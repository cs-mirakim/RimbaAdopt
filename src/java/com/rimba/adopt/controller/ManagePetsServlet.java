package com.rimba.adopt.controller;

import com.rimba.adopt.dao.PetsDAO;
import com.rimba.adopt.model.Pets;
import com.rimba.adopt.util.SessionUtil;
import java.io.*;
import java.sql.SQLException;
import java.util.List;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.*;

@WebServlet("/manage-pets")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024, // 1MB
        maxFileSize = 1024 * 1024 * 5, // 5MB
        maxRequestSize = 1024 * 1024 * 10 // 10MB
)
public class ManagePetsServlet extends HttpServlet {

    private static final String UPLOAD_DIR = "animal_picture";
    private static final String DEFAULT_IMAGE = "animal_picture/default.png";

    private PetsDAO petsDAO;

    @Override
    public void init() throws ServletException {
        petsDAO = new PetsDAO();
    }

    // ========== HELPER METHODS FOR FILE MANAGEMENT ==========
    /**
     * Delete old pet photo from both webapp and project locations
     */
    private boolean deleteOldPetPhoto(String photoPath, HttpServletRequest request) {
        if (photoPath == null || photoPath.isEmpty() || photoPath.equals(DEFAULT_IMAGE)) {
            return true; // No need to delete default image
        }

        try {
            ServletContext context = request.getServletContext();

            // === DELETE FROM WEBAPP LOCATION ===
            String webappPath = context.getRealPath("");
            if (webappPath == null) {
                webappPath = "";
            }

            String fullWebappPath = webappPath;
            if (!fullWebappPath.endsWith(File.separator)) {
                fullWebappPath += File.separator;
            }

            // Build full path
            String webappFilePath = fullWebappPath + photoPath.replace("/", File.separator);
            File webappFile = new File(webappFilePath);

            if (webappFile.exists()) {
                boolean deleted = webappFile.delete();
                System.out.println("DEBUG: Deleted webapp file: " + webappFilePath + " - " + deleted);
            }

            // === DELETE FROM PROJECT LOCATION ===
            String projectPath = "";
            try {
                File webappDir = new File(webappPath);
                File buildDir = webappDir.getParentFile();
                if (buildDir != null) {
                    File projectRoot = buildDir.getParentFile();
                    if (projectRoot != null) {
                        // Extract just the filename from photoPath
                        String fileName = new File(photoPath).getName();
                        projectPath = projectRoot.getAbsolutePath()
                                + File.separator + "web"
                                + File.separator + "animal_picture"
                                + File.separator + fileName;
                    }
                }
            } catch (Exception e) {
                System.err.println("Could not build project path for deletion: " + e.getMessage());
            }

            if (!projectPath.isEmpty()) {
                File projectFile = new File(projectPath);
                if (projectFile.exists()) {
                    boolean deleted = projectFile.delete();
                    System.out.println("DEBUG: Deleted project file: " + projectPath + " - " + deleted);
                }
            }

            return true;

        } catch (Exception e) {
            System.err.println("ERROR deleting old pet photo: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Save uploaded file to both webapp and project locations
     */
    private String handleFileUpload(HttpServletRequest request, int shelterId, String oldPhotoPath)
            throws ServletException, IOException {

        Part filePart = request.getPart("petPhoto");

        if (filePart == null || filePart.getSize() == 0) {
            return null; // No new file uploaded
        }

        String fileName = getFileName(filePart);
        if (fileName == null || fileName.isEmpty()) {
            return null;
        }

        String fileExtension = "";
        if (fileName.contains(".")) {
            fileExtension = fileName.substring(fileName.lastIndexOf(".")).toLowerCase();
        }

        // Validate file type
        if (!fileExtension.matches("\\.(jpg|jpeg|png|gif|bmp|webp)$")) {
            throw new ServletException("Invalid file type. Only images are allowed.");
        }

        // Validate file size (max 5MB)
        if (filePart.getSize() > 5 * 1024 * 1024) {
            throw new ServletException("File size exceeds 5MB limit.");
        }

        // === DELETE OLD PHOTO FIRST ===
        if (oldPhotoPath != null && !oldPhotoPath.isEmpty() && !oldPhotoPath.equals(DEFAULT_IMAGE)) {
            System.out.println("DEBUG: Deleting old photo before upload: " + oldPhotoPath);
            deleteOldPetPhoto(oldPhotoPath, request);
        }

        // Create unique filename
        String uniqueFileName = "pet_" + shelterId + "_" + System.currentTimeMillis() + fileExtension;

        try {
            ServletContext context = request.getServletContext();
            String roleFolder = "animal_picture/";

            // === WEBAPP LOCATION ===
            String webappPath = context.getRealPath("");
            if (webappPath == null) {
                webappPath = "";
            }

            String fullWebappPath = webappPath;
            if (!fullWebappPath.endsWith(File.separator)) {
                fullWebappPath += File.separator;
            }
            fullWebappPath += "animal_picture" + File.separator;

            // === PROJECT LOCATION ===
            String projectPath = "";
            try {
                File webappDir = new File(webappPath);
                File buildDir = webappDir.getParentFile();
                if (buildDir != null) {
                    File projectRoot = buildDir.getParentFile();
                    if (projectRoot != null) {
                        projectPath = projectRoot.getAbsolutePath()
                                + File.separator + "web"
                                + File.separator + "animal_picture"
                                + File.separator;
                    }
                }
            } catch (Exception e) {
                System.err.println("Could not build project path: " + e.getMessage());
                projectPath = fullWebappPath; // fallback
            }

            // Create directories
            File webappDir = new File(fullWebappPath);
            File projectDir = new File(projectPath);

            if (!webappDir.exists()) {
                webappDir.mkdirs();
            }
            if (!projectDir.exists()) {
                projectDir.mkdirs();
            }

            // === SAVE TO MULTIPLE LOCATIONS ===
            String webappFilePath = fullWebappPath + uniqueFileName;
            String projectFilePath = projectPath + uniqueFileName;

            boolean filesSaved = saveFileToMultipleLocations(filePart, webappFilePath, projectFilePath);

            System.out.println("DEBUG: Pet image saved: " + filesSaved);
            System.out.println("DEBUG: Webapp path: " + webappFilePath);
            System.out.println("DEBUG: Project path: " + projectFilePath);

            // Return relative path for database
            return roleFolder + uniqueFileName;

        } catch (Exception e) {
            System.err.println("ERROR in handleFileUpload: " + e.getMessage());
            e.printStackTrace();
            throw new ServletException("Failed to save uploaded file: " + e.getMessage(), e);
        }
    }

    /**
     * Helper to save file to multiple locations
     */
    private boolean saveFileToMultipleLocations(Part filePart, String... filePaths) throws IOException {
        try (InputStream input = filePart.getInputStream()) {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buffer = new byte[1024];
            int bytesRead;
            while ((bytesRead = input.read(buffer)) != -1) {
                baos.write(buffer, 0, bytesRead);
            }
            byte[] fileData = baos.toByteArray();

            System.out.println("DEBUG: File data size: " + fileData.length + " bytes");

            boolean allSuccess = true;
            for (String filePath : filePaths) {
                try (FileOutputStream output = new FileOutputStream(filePath)) {
                    output.write(fileData);
                    System.out.println("DEBUG: Saved to: " + filePath);
                } catch (IOException e) {
                    System.err.println("ERROR: Failed to save to: " + filePath);
                    e.printStackTrace();
                    allSuccess = false;
                }
            }
            return allSuccess;
        }
    }

    /**
     * Extract filename from Part
     */
    private String getFileName(Part part) {
        String contentDisposition = part.getHeader("content-disposition");
        if (contentDisposition != null) {
            String[] items = contentDisposition.split(";");
            for (String item : items) {
                if (item.trim().startsWith("filename")) {
                    String fileName = item.substring(item.indexOf("=") + 2, item.length() - 1);
                    return new File(fileName).getName();
                }
            }
        }
        return null;
    }

    private String getParameter(HttpServletRequest request, String paramName) {
        String value = request.getParameter(paramName);
        if (value != null) {
            value = value.trim();
            if (value.isEmpty()) {
                return null;
            }
        }
        return value;
    }

    // ========== MAIN SERVLET METHODS ==========
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (!SessionUtil.isLoggedIn(session)) {
            response.sendRedirect("login.jsp");
            return;
        }

        if (!SessionUtil.isShelter(session)) {
            response.sendRedirect("index.jsp");
            return;
        }

        try {
            int userId = SessionUtil.getUserId(session);
            int shelterId = userId;

            String filterStatus = request.getParameter("filterStatus");
            String searchTerm = request.getParameter("search");
            String viewType = request.getParameter("view");

            List<Pets> pets;

            // Apply filters
            if (searchTerm != null && !searchTerm.trim().isEmpty()) {
                if (filterStatus != null && !filterStatus.equals("all")) {
                    pets = petsDAO.searchPetsByStatus(shelterId, searchTerm.trim(), filterStatus);
                } else {
                    pets = petsDAO.searchPets(shelterId, searchTerm.trim());
                }
            } else if (filterStatus != null && !filterStatus.equals("all")) {
                pets = petsDAO.getPetsByStatus(shelterId, filterStatus);
            } else if ("available".equals(viewType)) {
                pets = petsDAO.getAvailablePetsByShelter(shelterId);
            } else {
                pets = petsDAO.getPetsByShelter(shelterId);
            }

            // Get counts for statistics
            int totalPets = petsDAO.getPetCountByShelter(shelterId);
            int availablePets = petsDAO.getPetCountByStatus(shelterId, "available");
            int adoptedPets = petsDAO.getPetCountByStatus(shelterId, "adopted");

            request.setAttribute("pets", pets);
            request.setAttribute("totalPets", totalPets);
            request.setAttribute("availablePets", availablePets);
            request.setAttribute("adoptedPets", adoptedPets);
            request.setAttribute("filterStatus", filterStatus);
            request.setAttribute("searchTerm", searchTerm);
            request.setAttribute("viewType", viewType);

            RequestDispatcher dispatcher = request.getRequestDispatcher("manage_pets.jsp");
            dispatcher.forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            session.setAttribute("error", "Database error: " + e.getMessage());
            response.sendRedirect("manage_pets.jsp");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();

        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isShelter(session)) {
            response.sendRedirect("login.jsp");
            return;
        }

        String action = request.getParameter("action");

        try {
            int userId = SessionUtil.getUserId(session);
            int shelterId = userId;

            if ("create".equals(action)) {
                createPet(request, response, shelterId, session);
            } else if ("update".equals(action)) {
                updatePet(request, response, shelterId, session);
            } else if ("delete".equals(action)) {
                deletePet(request, response, shelterId, session);
            } else if ("updateStatus".equals(action)) {
                updatePetStatus(request, response, shelterId, session);
            } else {
                response.sendRedirect("manage-pets");
            }

        } catch (SQLException e) {
            e.printStackTrace();
            session.setAttribute("error", "Database error: " + e.getMessage());
            response.sendRedirect("manage-pets");
        } catch (Exception e) {
            e.printStackTrace();
            session.setAttribute("error", "Error: " + e.getMessage());
            response.sendRedirect("manage-pets");
        }
    }

    private void createPet(HttpServletRequest request, HttpServletResponse response, int shelterId, HttpSession session)
            throws ServletException, IOException, SQLException {

        // Get form parameters
        String name = getParameter(request, "petName");
        String species = getParameter(request, "species");
        String breed = getParameter(request, "breed");
        String ageStr = getParameter(request, "age");
        String gender = getParameter(request, "gender");
        String size = getParameter(request, "size");
        String color = getParameter(request, "color");
        String healthStatus = getParameter(request, "healthStatus");
        String description = getParameter(request, "description");
        String adoptionStatus = getParameter(request, "adoptionStatus");

        // Validate required fields
        if (name == null || name.trim().isEmpty()
                || species == null || species.trim().isEmpty()
                || gender == null || gender.trim().isEmpty()
                || size == null || size.trim().isEmpty()) {
            session.setAttribute("error", "Please fill in all required fields (Name, Species, Gender, Size).");
            response.sendRedirect("manage-pets");
            return;
        }

        // Set default adoption status if not provided
        if (adoptionStatus == null || adoptionStatus.trim().isEmpty()) {
            adoptionStatus = "available";
        } else if (!adoptionStatus.equals("available") && !adoptionStatus.equals("adopted")) {
            adoptionStatus = "available";
        }

        // Handle file upload (no old photo to delete for create)
        String photoPath = DEFAULT_IMAGE;
        Part filePart = request.getPart("petPhoto");
        if (filePart != null && filePart.getSize() > 0) {
            System.out.println("DEBUG: Creating pet with uploaded file");
            String uploadedPath = handleFileUpload(request, shelterId, null);
            if (uploadedPath != null && !uploadedPath.trim().isEmpty()) {
                photoPath = uploadedPath;
            }
        }

        // Convert age
        Integer age = null;
        if (ageStr != null && !ageStr.trim().isEmpty()) {
            try {
                age = Integer.parseInt(ageStr.trim());
                if (age < 0 || age > 30) {
                    session.setAttribute("error", "Age must be between 0 and 30.");
                    response.sendRedirect("manage-pets");
                    return;
                }
            } catch (NumberFormatException e) {
                session.setAttribute("error", "Invalid age format.");
                response.sendRedirect("manage-pets");
                return;
            }
        }

        // Create Pets object
        Pets pet = new Pets();
        pet.setShelterId(shelterId);
        pet.setName(name.trim());
        pet.setSpecies(species.trim());
        pet.setBreed(breed != null && !breed.trim().isEmpty() ? breed.trim() : null);
        pet.setAge(age);
        pet.setGender(gender.trim());
        pet.setSize(size.trim());
        pet.setColor(color != null && !color.trim().isEmpty() ? color.trim() : null);
        pet.setDescription(description != null && !description.trim().isEmpty() ? description.trim() : null);
        pet.setHealthStatus(healthStatus != null && !healthStatus.trim().isEmpty() ? healthStatus.trim() : null);
        pet.setPhotoPath(photoPath);
        pet.setAdoptionStatus(adoptionStatus.trim());

        System.out.println("DEBUG: Creating pet with photo path: " + photoPath);

        // Save to database
        int petId = petsDAO.createPet(pet);

        if (petId > 0) {
            session.setAttribute("success", "Pet '" + name + "' added successfully!");
        } else {
            session.setAttribute("error", "Failed to add pet. Please try again.");
        }

        response.sendRedirect("manage-pets");
    }

    private void updatePet(HttpServletRequest request, HttpServletResponse response, int shelterId, HttpSession session)
            throws ServletException, IOException, SQLException {

        // Get form parameters
        String petIdStr = getParameter(request, "petId");
        String name = getParameter(request, "petName");
        String species = getParameter(request, "species");
        String breed = getParameter(request, "breed");
        String ageStr = getParameter(request, "age");
        String gender = getParameter(request, "gender");
        String size = getParameter(request, "size");
        String color = getParameter(request, "color");
        String healthStatus = getParameter(request, "healthStatus");
        String description = getParameter(request, "description");
        String adoptionStatus = getParameter(request, "adoptionStatus");
        String existingPhotoPath = getParameter(request, "existingPhotoPath");

        // Validate required fields
        if (petIdStr == null || petIdStr.trim().isEmpty()
                || name == null || name.trim().isEmpty()
                || species == null || species.trim().isEmpty()
                || gender == null || gender.trim().isEmpty()
                || size == null || size.trim().isEmpty()) {
            session.setAttribute("error", "Please fill in all required fields.");
            response.sendRedirect("manage-pets");
            return;
        }

        int petId = Integer.parseInt(petIdStr.trim());

        // Verify pet belongs to this shelter
        Pets existingPet = petsDAO.getPetByIdAndShelter(petId, shelterId);
        if (existingPet == null) {
            session.setAttribute("error", "Pet not found or you don't have permission to edit it.");
            response.sendRedirect("manage-pets");
            return;
        }

        // Store old photo path for deletion if new file uploaded
        String oldPhotoPath = existingPet.getPhotoPath();
        String photoPath = oldPhotoPath;

        // Handle file upload - ONLY if new file is uploaded
        Part filePart = request.getPart("petPhoto");
        if (filePart != null && filePart.getSize() > 0) {
            System.out.println("DEBUG: New file uploaded for pet update");
            String newPhotoPath = handleFileUpload(request, shelterId, oldPhotoPath);
            if (newPhotoPath != null && !newPhotoPath.trim().isEmpty()) {
                photoPath = newPhotoPath;
                System.out.println("DEBUG: Updated photo path to: " + photoPath);
            }
        } else {
            // Keep existing photo
            System.out.println("DEBUG: No new file uploaded, keeping existing photo: " + photoPath);

            // Check if user wants to remove photo (checkbox or similar)
            String removePhoto = getParameter(request, "removePhoto");
            if ("true".equals(removePhoto) && photoPath != null && !photoPath.equals(DEFAULT_IMAGE)) {
                System.out.println("DEBUG: User requested to remove photo");
                deleteOldPetPhoto(photoPath, request);
                photoPath = DEFAULT_IMAGE;
            }
        }

        // Fix old path format if needed
        if (photoPath != null && photoPath.startsWith("profile_picture/pet/")) {
            photoPath = photoPath.replace("profile_picture/pet/", "animal_picture/");
        }

        // Convert age
        Integer age = null;
        if (ageStr != null && !ageStr.trim().isEmpty()) {
            try {
                age = Integer.parseInt(ageStr.trim());
                if (age < 0 || age > 30) {
                    session.setAttribute("error", "Age must be between 0 and 30.");
                    response.sendRedirect("manage-pets");
                    return;
                }
            } catch (NumberFormatException e) {
                session.setAttribute("error", "Invalid age format.");
                response.sendRedirect("manage-pets");
                return;
            }
        }

        // Update Pets object
        existingPet.setName(name.trim());
        existingPet.setSpecies(species.trim());
        existingPet.setBreed(breed != null && !breed.trim().isEmpty() ? breed.trim() : null);
        existingPet.setAge(age);
        existingPet.setGender(gender.trim());
        existingPet.setSize(size.trim());
        existingPet.setColor(color != null && !color.trim().isEmpty() ? color.trim() : null);
        existingPet.setDescription(description != null && !description.trim().isEmpty() ? description.trim() : null);
        existingPet.setHealthStatus(healthStatus != null && !healthStatus.trim().isEmpty() ? healthStatus.trim() : null);
        existingPet.setPhotoPath(photoPath);

        if (adoptionStatus != null && !adoptionStatus.trim().isEmpty()) {
            if (adoptionStatus.equals("available") || adoptionStatus.equals("adopted")) {
                existingPet.setAdoptionStatus(adoptionStatus.trim());
            }
        }

        System.out.println("DEBUG: Updating pet with final photo path: " + photoPath);

        // Update in database
        boolean success = petsDAO.updatePet(existingPet);

        if (success) {
            session.setAttribute("success", "Pet '" + name + "' updated successfully!");
        } else {
            session.setAttribute("error", "Failed to update pet. Please try again.");
        }

        response.sendRedirect("manage-pets");
    }

    private void updatePetStatus(HttpServletRequest request, HttpServletResponse response, int shelterId, HttpSession session)
            throws ServletException, IOException, SQLException {

        String petIdStr = getParameter(request, "petId");
        String adoptionStatus = getParameter(request, "adoptionStatus");

        if (petIdStr == null || petIdStr.trim().isEmpty()
                || adoptionStatus == null || adoptionStatus.trim().isEmpty()) {
            session.setAttribute("error", "Pet ID and status are required.");
            response.sendRedirect("manage-pets");
            return;
        }

        int petId = Integer.parseInt(petIdStr.trim());

        // Verify pet belongs to this shelter
        Pets pet = petsDAO.getPetByIdAndShelter(petId, shelterId);
        if (pet == null) {
            session.setAttribute("error", "Pet not found or you don't have permission to update it.");
            response.sendRedirect("manage-pets");
            return;
        }

        // Update adoption status
        boolean success = petsDAO.updateAdoptionStatus(petId, shelterId, adoptionStatus.trim());

        if (success) {
            session.setAttribute("success", "Pet '" + pet.getName() + "' status updated to '" + adoptionStatus + "'");
        } else {
            session.setAttribute("error", "Failed to update pet status.");
        }

        response.sendRedirect("manage-pets");
    }

    private void deletePet(HttpServletRequest request, HttpServletResponse response, int shelterId, HttpSession session)
            throws ServletException, IOException, SQLException {

        String petIdStr = getParameter(request, "petId");

        if (petIdStr == null || petIdStr.trim().isEmpty()) {
            session.setAttribute("error", "Pet ID is required for deletion.");
            response.sendRedirect("manage-pets");
            return;
        }

        int petId = Integer.parseInt(petIdStr.trim());

        // Verify pet belongs to this shelter and get photo path BEFORE deletion
        Pets pet = petsDAO.getPetByIdAndShelter(petId, shelterId);
        if (pet == null) {
            session.setAttribute("error", "Pet not found or you don't have permission to delete it.");
            response.sendRedirect("manage-pets");
            return;
        }

        String petName = pet.getName();
        String photoPath = pet.getPhotoPath();

        // DELETE PHOTO FILE FIRST
        if (photoPath != null && !photoPath.equals(DEFAULT_IMAGE)) {
            System.out.println("DEBUG: Deleting pet photo before database deletion: " + photoPath);
            deleteOldPetPhoto(photoPath, request);
        }

        // DELETE FROM DATABASE
        boolean success = petsDAO.deletePet(petId, shelterId);

        if (success) {
            session.setAttribute("success", "Pet '" + petName + "' deleted successfully!");
        } else {
            session.setAttribute("error", "Failed to delete pet. Please try again.");
        }

        response.sendRedirect("manage-pets");
    }
}
