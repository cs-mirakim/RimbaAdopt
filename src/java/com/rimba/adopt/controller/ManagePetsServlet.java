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
    fileSizeThreshold = 1024 * 1024,  // 1MB
    maxFileSize = 1024 * 1024 * 5,    // 5MB
    maxRequestSize = 1024 * 1024 * 10 // 10MB
)
public class ManagePetsServlet extends HttpServlet {
    
    private PetsDAO petsDAO;
    
    @Override
    public void init() throws ServletException {
        petsDAO = new PetsDAO();
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        
        // Check if user is logged in and is a shelter using existing SessionUtil
        if (!SessionUtil.isLoggedIn(session)) {
            response.sendRedirect("index.jsp");
            return;
        }
        
        if (!SessionUtil.isShelter(session)) {
            response.sendRedirect("index.jsp");
            return;
        }
        
        try {
            // Get shelter_id - for shelter users, user_id = shelter_id
            // Use existing SessionUtil.getUserId() method
            int userId = SessionUtil.getUserId(session);
            int shelterId = userId; // In your schema, shelter_id = user_id
            
            // Check for search parameter
            String searchTerm = request.getParameter("search");
            List<Pets> pets;
            
            if (searchTerm != null && !searchTerm.trim().isEmpty()) {
                pets = petsDAO.searchPets(shelterId, searchTerm.trim());
            } else {
                pets = petsDAO.getPetsByShelter(shelterId);
            }
            
            request.setAttribute("pets", pets);
            
            // Forward to JSP
            RequestDispatcher dispatcher = request.getRequestDispatcher("/manage_pets.jsp");
            dispatcher.forward(request, response);
            
        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("error", "Database error: " + e.getMessage());
            RequestDispatcher dispatcher = request.getRequestDispatcher("/error.jsp");
            dispatcher.forward(request, response);
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession();
        
        // Check if user is logged in and is a shelter using existing SessionUtil
        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isShelter(session)) {
            response.sendRedirect("index.jsp");
            return;
        }
        
        String action = request.getParameter("action");
        
        try {
            // Get shelter_id - for shelter users, user_id = shelter_id
            // Use existing SessionUtil.getUserId() method
            int userId = SessionUtil.getUserId(session);
            int shelterId = userId; // In your schema, shelter_id = user_id
            
            if ("create".equals(action)) {
                createPet(request, response, shelterId, session);
            } else if ("update".equals(action)) {
                updatePet(request, response, shelterId, session);
            } else if ("delete".equals(action)) {
                deletePet(request, response, shelterId, session);
            } else {
                response.sendRedirect("manage-pets");
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
            session.setAttribute("error", "Database error: " + e.getMessage());
            response.sendRedirect("manage-pets");
        } catch (NumberFormatException e) {
            e.printStackTrace();
            session.setAttribute("error", "Invalid input format: " + e.getMessage());
            response.sendRedirect("manage-pets");
        }
    }
    
    private void createPet(HttpServletRequest request, HttpServletResponse response, int shelterId, HttpSession session)
            throws ServletException, IOException, SQLException {
        
        // Get form parameters
        String name = request.getParameter("petName");
        String species = request.getParameter("species");
        String breed = request.getParameter("breed");
        String ageStr = request.getParameter("age");
        String gender = request.getParameter("gender");
        String size = request.getParameter("size");
        String color = request.getParameter("color");
        String healthStatus = request.getParameter("healthStatus");
        String description = request.getParameter("description");
        
        // Validate required fields
        if (name == null || name.trim().isEmpty() || 
            species == null || species.trim().isEmpty() || 
            gender == null || gender.trim().isEmpty() || 
            size == null || size.trim().isEmpty()) {
            session.setAttribute("error", "Please fill in all required fields.");
            response.sendRedirect("manage-pets");
            return;
        }
        
        // Handle file upload
        String photoPath = handleFileUpload(request, shelterId);
        
        // Convert age
        Integer age = null;
        if (ageStr != null && !ageStr.trim().isEmpty()) {
            try {
                age = Integer.parseInt(ageStr.trim());
            } catch (NumberFormatException e) {
                // Age will remain null
            }
        }
        
        // Create Pets object
        Pets pet = new Pets();
        pet.setShelterId(shelterId);
        pet.setName(name.trim());
        pet.setSpecies(species.trim());
        pet.setBreed(breed != null ? breed.trim() : null);
        pet.setAge(age);
        pet.setGender(gender.trim());
        pet.setSize(size.trim());
        pet.setColor(color != null ? color.trim() : null);
        pet.setDescription(description != null ? description.trim() : null);
        pet.setHealthStatus(healthStatus != null ? healthStatus.trim() : null);
        pet.setPhotoPath(photoPath);
        
        // Save to database
        int petId = petsDAO.createPet(pet);
        
        if (petId > 0) {
            session.setAttribute("success", "Pet added successfully!");
        } else {
            session.setAttribute("error", "Failed to add pet. Please try again.");
        }
        
        response.sendRedirect("manage-pets");
    }
    
    private void updatePet(HttpServletRequest request, HttpServletResponse response, int shelterId, HttpSession session)
            throws ServletException, IOException, SQLException {
        
        // Get form parameters
        String petIdStr = request.getParameter("petId");
        String name = request.getParameter("petName");
        String species = request.getParameter("species");
        String breed = request.getParameter("breed");
        String ageStr = request.getParameter("age");
        String gender = request.getParameter("gender");
        String size = request.getParameter("size");
        String color = request.getParameter("color");
        String healthStatus = request.getParameter("healthStatus");
        String description = request.getParameter("description");
        String existingPhotoPath = request.getParameter("existingPhotoPath");
        
        // Validate required fields
        if (petIdStr == null || petIdStr.trim().isEmpty() ||
            name == null || name.trim().isEmpty() || 
            species == null || species.trim().isEmpty() || 
            gender == null || gender.trim().isEmpty() || 
            size == null || size.trim().isEmpty()) {
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
        
        // Handle file upload - use existing if no new file uploaded
        String photoPath = existingPhotoPath;
        Part filePart = request.getPart("petPhoto");
        if (filePart != null && filePart.getSize() > 0) {
            String newPhotoPath = handleFileUpload(request, shelterId);
            if (newPhotoPath != null) {
                photoPath = newPhotoPath;
            }
        }
        
        // Convert age
        Integer age = null;
        if (ageStr != null && !ageStr.trim().isEmpty()) {
            try {
                age = Integer.parseInt(ageStr.trim());
            } catch (NumberFormatException e) {
                // Age will remain null
            }
        }
        
        // Update Pets object
        existingPet.setName(name.trim());
        existingPet.setSpecies(species.trim());
        existingPet.setBreed(breed != null ? breed.trim() : null);
        existingPet.setAge(age);
        existingPet.setGender(gender.trim());
        existingPet.setSize(size.trim());
        existingPet.setColor(color != null ? color.trim() : null);
        existingPet.setDescription(description != null ? description.trim() : null);
        existingPet.setHealthStatus(healthStatus != null ? healthStatus.trim() : null);
        existingPet.setPhotoPath(photoPath);
        
        // Update in database
        boolean success = petsDAO.updatePet(existingPet);
        
        if (success) {
            session.setAttribute("success", "Pet updated successfully!");
        } else {
            session.setAttribute("error", "Failed to update pet. Please try again.");
        }
        
        response.sendRedirect("manage-pets");
    }
    
    private void deletePet(HttpServletRequest request, HttpServletResponse response, int shelterId, HttpSession session)
            throws ServletException, IOException, SQLException {
        
        String petIdStr = request.getParameter("petId");
        
        if (petIdStr == null || petIdStr.trim().isEmpty()) {
            session.setAttribute("error", "Pet ID is required for deletion.");
            response.sendRedirect("manage-pets");
            return;
        }
        
        int petId = Integer.parseInt(petIdStr.trim());
        
        // Verify pet belongs to this shelter before deleting
        Pets pet = petsDAO.getPetByIdAndShelter(petId, shelterId);
        if (pet == null) {
            session.setAttribute("error", "Pet not found or you don't have permission to delete it.");
            response.sendRedirect("manage-pets");
            return;
        }
        
        // Delete from database
        boolean success = petsDAO.deletePet(petId, shelterId);
        
        if (success) {
            session.setAttribute("success", "Pet deleted successfully!");
        } else {
            session.setAttribute("error", "Failed to delete pet. Please try again.");
        }
        
        response.sendRedirect("manage-pets");
    }
    
    private String handleFileUpload(HttpServletRequest request, int shelterId) 
        throws ServletException, IOException {
    
    Part filePart = request.getPart("petPhoto");
    
    if (filePart == null || filePart.getSize() == 0) {
        return "animal_picture/default_pet.jpg"; // Default image path
    }
    
    // Validate file type
    String fileName = filePart.getSubmittedFileName();
    if (fileName == null || fileName.isEmpty()) {
        return "animal_picture/default_pet.jpg";
    }
    
    String fileExtension = fileName.substring(fileName.lastIndexOf(".")).toLowerCase();
    
    if (!fileExtension.matches("\\.(jpg|jpeg|png|gif|bmp)$")) {
        throw new ServletException("Invalid file type. Only images are allowed.");
    }
    
    // Validate file size (max 5MB)
    if (filePart.getSize() > 5 * 1024 * 1024) {
        throw new ServletException("File size exceeds 5MB limit.");
    }
    
    // Create unique filename
    String uniqueFileName = "pet_" + shelterId + "_" + System.currentTimeMillis() + fileExtension;
    
    try {
        // Dapatkan application context path
        ServletContext context = getServletContext();
        
        // === DEBUG LOGGING ===
        System.out.println("=== PET FILE UPLOAD DEBUG ===");
        System.out.println("Shelter ID: " + shelterId);
        System.out.println("Original filename: " + fileName);
        System.out.println("File size: " + filePart.getSize() + " bytes");
        System.out.println("Generated filename: " + uniqueFileName);
        
        // Path untuk animal_picture folder dalam webapp
        String webappPath = context.getRealPath("");
        if (webappPath == null) {
            webappPath = "";
        }
        
        // FIX PATH: Tambah separator yang betul
        String fullWebappPath = webappPath;
        if (!fullWebappPath.endsWith(File.separator)) {
            fullWebappPath += File.separator;
        }
        fullWebappPath += "animal_picture" + File.separator;
        
        // Path untuk animal_picture dalam source project
        String projectPath = "";
        try {
            // FIX: Build path dengan betul
            File webappDir = new File(webappPath);
            File buildDir = webappDir.getParentFile(); // build folder
            if (buildDir != null) {
                File projectRoot = buildDir.getParentFile(); // project root
                if (projectRoot != null) {
                    projectPath = projectRoot.getAbsolutePath()
                            + File.separator + "web"
                            + File.separator + "animal_picture"
                            + File.separator;
                }
            }
        } catch (Exception e) {
            System.out.println("Could not build project path: " + e.getMessage());
            projectPath = fullWebappPath; // fallback
        }
        
        System.out.println("Webapp Path: " + fullWebappPath);
        System.out.println("Project Path: " + projectPath);
        
        // Buat directory
        File webappDir = new File(fullWebappPath);
        File projectDir = new File(projectPath);
        
        if (!webappDir.exists()) {
            boolean created = webappDir.mkdirs();
            System.out.println("Created webapp directory: " + created);
        }
        
        if (!projectDir.exists()) {
            boolean created = projectDir.mkdirs();
            System.out.println("Created project directory: " + created);
        }
        
        // === SAVE TO BOTH LOCATIONS ===
        String webappFilePath = fullWebappPath + uniqueFileName;
        String projectFilePath = projectPath + uniqueFileName;
        
        // Call helper method untuk save multiple locations
        boolean filesSaved = saveFileToMultipleLocations(filePart, webappFilePath, projectFilePath);
        
        System.out.println("Files saved successfully: " + filesSaved);
        
        // Debug: Check if files exist
        File webappFile = new File(webappFilePath);
        File projectFile = new File(projectFilePath);
        
        System.out.println("Webapp file exists: " + webappFile.exists() + ", size: " + webappFile.length() + " bytes");
        System.out.println("Project file exists: " + projectFile.exists() + ", size: " + projectFile.length() + " bytes");
        
        System.out.println("=== FILE UPLOAD DEBUG END ===");
        
        // Return relative path untuk database
        return "animal_picture/" + uniqueFileName;
        
    } catch (Exception e) {
        System.out.println("Error in handleFileUpload method: " + e.getMessage());
        e.printStackTrace();
        return "animal_picture/default_pet.jpg"; // Return default if error
    }
}

// Helper method untuk save ke multiple locations (SAMA seperti RegistrationServlet)
private boolean saveFileToMultipleLocations(Part filePart, String... filePaths) throws IOException {
    try (InputStream input = filePart.getInputStream()) {
        // Read all data first
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        byte[] buffer = new byte[1024];
        int bytesRead;
        while ((bytesRead = input.read(buffer)) != -1) {
            baos.write(buffer, 0, bytesRead);
        }
        byte[] fileData = baos.toByteArray();
        
        System.out.println("File data read: " + fileData.length + " bytes");
        
        // Write to each location
        boolean allSuccess = true;
        for (String filePath : filePaths) {
            try (FileOutputStream output = new FileOutputStream(filePath)) {
                output.write(fileData);
                System.out.println("Saved to: " + filePath);
            } catch (IOException e) {
                System.out.println("Failed to save to: " + filePath + " - " + e.getMessage());
                allSuccess = false;
            }
        }
        return allSuccess;
    }
}
}