package com.rimba.adopt.controller;

import com.rimba.adopt.dao.UsersDao;
import com.rimba.adopt.model.Users;
import com.rimba.adopt.model.Shelter;
import com.rimba.adopt.model.Adopter;
import com.rimba.adopt.util.DatabaseConnection;
import java.io.*;
import java.sql.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.servlet.*;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@MultipartConfig(
        fileSizeThreshold = 1024 * 1024, // 1MB
        maxFileSize = 1024 * 1024 * 2, // 2MB max
        maxRequestSize = 1024 * 1024 * 5 // 5MB
)

@WebServlet("/RegistrationServlet")
public class RegistrationServlet extends HttpServlet {

    private static final Logger logger = Logger.getLogger(RegistrationServlet.class.getName());

    // Password hashing dengan SHA-256
    private String hashPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hash = md.digest(password.getBytes("UTF-8"));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException | UnsupportedEncodingException e) {
            logger.log(Level.SEVERE, "Error hashing password", e);
            return password; // Fallback
        }
    }

    // Save uploaded file method dengan path yang tepat dan organize by role
    private String saveProfilePhoto(Part filePart, HttpServletRequest request, String email, String role) throws IOException {
        if (filePart == null || filePart.getSize() == 0 || filePart.getSubmittedFileName() == null) {
            logger.info("No file uploaded or empty file");
            return null;
        }

        try {
            // Dapatkan application context path
            ServletContext context = request.getServletContext();

            // Determine folder based on role
            String roleFolder = "profile_picture/" + role.toLowerCase() + "/";

            // === DEBUG LOGGING ===
            logger.info("=== FILE UPLOAD DEBUG START ===");
            logger.info("Role: " + role);
            logger.info("Email: " + email);
            logger.info("Original filename: " + filePart.getSubmittedFileName());
            logger.info("File size: " + filePart.getSize() + " bytes");

            // Path untuk simpan dalam webapp (untuk access via browser)
            String webappPath = context.getRealPath("");
            if (webappPath == null) {
                webappPath = "";
            }

            // FIX PATH: Tambah separator yang betul
            String fullWebappPath = webappPath;
            if (!fullWebappPath.endsWith(File.separator)) {
                fullWebappPath += File.separator;
            }
            fullWebappPath += "profile_picture" + File.separator + role.toLowerCase() + File.separator;

            // Path untuk simpan dalam source project
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
                                + File.separator + "profile_picture"
                                + File.separator + role.toLowerCase()
                                + File.separator;
                    }
                }
            } catch (Exception e) {
                logger.log(Level.WARNING, "Could not build project path: " + e.getMessage());
                projectPath = fullWebappPath; // fallback
            }

            logger.info("Webapp Path: " + fullWebappPath);
            logger.info("Project Path: " + projectPath);

            // Buat directory
            File webappDir = new File(fullWebappPath);
            File projectDir = new File(projectPath);

            if (!webappDir.exists()) {
                boolean created = webappDir.mkdirs();
                logger.info("Created webapp directory: " + created);
            }

            if (!projectDir.exists()) {
                boolean created = projectDir.mkdirs();
                logger.info("Created project directory: " + created);
            }

            // Generate unique filename
            String originalFileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
            String fileExtension = "";

            int dotIndex = originalFileName.lastIndexOf('.');
            if (dotIndex > 0) {
                fileExtension = originalFileName.substring(dotIndex).toLowerCase();
            }

            String sanitizedEmail = email.replaceAll("[^a-zA-Z0-9._-]", "_");
            String fileName = sanitizedEmail + "_" + System.currentTimeMillis() + fileExtension;

            logger.info("Generated filename: " + fileName);

            // === FIX: SAVE TO BOTH LOCATIONS ===
            String webappFilePath = fullWebappPath + fileName;
            String projectFilePath = projectPath + fileName;

            // Call the NEW method to save to multiple locations
            boolean filesSaved = saveFileToMultipleLocations(filePart, webappFilePath, projectFilePath);

            logger.info("Files saved successfully: " + filesSaved);

            // Debug: Check if files exist
            File webappFile = new File(webappFilePath);
            File projectFile = new File(projectFilePath);

            logger.info("Webapp file exists: " + webappFile.exists() + ", size: " + webappFile.length() + " bytes");
            logger.info("Project file exists: " + projectFile.exists() + ", size: " + projectFile.length() + " bytes");

            logger.info("=== FILE UPLOAD DEBUG END ===");

            // Return relative path untuk database
            return roleFolder + fileName;

        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error in saveProfilePhoto method", e);
            return null;
        }
    }

    // Helper method YANG BARU untuk handle multiple writes
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

            logger.info("File data read: " + fileData.length + " bytes");

            // Write to each location
            boolean allSuccess = true;
            for (String filePath : filePaths) {
                try (FileOutputStream output = new FileOutputStream(filePath)) {
                    output.write(fileData);
                    logger.info("Saved to: " + filePath);
                } catch (IOException e) {
                    logger.log(Level.WARNING, "Failed to save to: " + filePath, e);
                    allSuccess = false;
                }
            }
            return allSuccess;
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html; charset=UTF-8");

        Connection conn = null;
        boolean registrationSuccess = false;
        String message = "";
        String redirectPage = "register.jsp";

        try {
            // Dapatkan database connection dari DatabaseConnection class
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false); // Start transaction

            UsersDao usersDao = new UsersDao(conn);

            // Get form parameters
            String role = request.getParameter("reg_role"); // "adopter" or "shelter"
            String name = request.getParameter("full_name");
            String email = request.getParameter("email");
            String password = request.getParameter("password");
            String confirmPassword = request.getParameter("confirm_password");
            String phone = request.getParameter("phone");

            logger.info("Processing registration for: " + email + ", Role: " + role);

            // Check if email already exists
            if (usersDao.isEmailExists(email)) {
                message = "Email already registered. Please use another email.";
                request.setAttribute("errorMessage", message);
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            // Validate password match
            if (!password.equals(confirmPassword)) {
                message = "Password and Confirm Password do not match.";
                request.setAttribute("errorMessage", message);
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            // Validate password length
            if (password.length() < 6) {
                message = "Password must be at least 6 characters long.";
                request.setAttribute("errorMessage", message);
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            // Save profile photo dengan role
            Part filePart = request.getPart("profile_photo");
            String profilePhotoPath = saveProfilePhoto(filePart, request, email, role);

            // Debug
            logger.info("Profile photo path: " + profilePhotoPath);

            // Create Users object
            Users user = new Users();
            user.setName(name);
            user.setEmail(email);
            user.setPassword(hashPassword(password)); // Hash password dengan SHA-256
            user.setPhone(phone);
            user.setRole(role);
            user.setProfilePhotoPath(profilePhotoPath); // Boleh null jika tak upload

            // Insert into users table
            int userId = usersDao.createUser(user);
            logger.info("User created with ID: " + userId);

            if ("shelter".equals(role)) {
                // Validate shelter required fields
                String shelterName = request.getParameter("shelter_name");
                String shelterAddress = request.getParameter("shelter_address");
                String shelterDesc = request.getParameter("shelter_desc");

                if (shelterName == null || shelterName.trim().isEmpty()
                        || shelterAddress == null || shelterAddress.trim().isEmpty()) {
                    message = "Shelter name and address are required.";
                    request.setAttribute("errorMessage", message);
                    request.getRequestDispatcher("register.jsp").forward(request, response);
                    return;
                }

                // Create Shelter object
                Shelter shelter = new Shelter();
                shelter.setShelterName(shelterName);
                shelter.setShelterAddress(shelterAddress);
                shelter.setShelterDescription(shelterDesc);
                shelter.setWebsite(request.getParameter("website"));

                // Combine operating hours
                String hoursFrom = request.getParameter("hours_from");
                String hoursTo = request.getParameter("hours_to");
                if (hoursFrom != null && hoursTo != null
                        && !hoursFrom.trim().isEmpty() && !hoursTo.trim().isEmpty()) {
                    shelter.setOperatingHours(hoursFrom + " - " + hoursTo);
                } else {
                    shelter.setOperatingHours("09:00 - 17:00");
                }

                shelter.setApprovalStatus("pending"); // Default status

                // Insert into shelter table
                boolean shelterCreated = usersDao.createShelter(shelter, userId);

                if (shelterCreated) {
                    logger.info("Shelter created for user ID: " + userId);
                    message = "🏠 Shelter registered successfully! Your account is pending admin approval. "
                            + "You will be notified via email once approved.";
                    redirectPage = "login.jsp";
                    registrationSuccess = true;
                }

            } else if ("adopter".equals(role)) {
                // Validate adopter required fields
                String address = request.getParameter("address");
                String occupation = request.getParameter("occupation");
                String household = request.getParameter("household");

                if (address == null || address.trim().isEmpty()
                        || occupation == null || occupation.trim().isEmpty()
                        || household == null || household.trim().isEmpty()) {
                    message = "Address, occupation, and household type are required.";
                    request.setAttribute("errorMessage", message);
                    request.getRequestDispatcher("register.jsp").forward(request, response);
                    return;
                }

                // Create Adopter object
                Adopter adopter = new Adopter();
                adopter.setAddress(address);
                adopter.setOccupation(occupation);
                adopter.setHouseholdType(household);

                // Handle checkbox (if checked, value is "on")
                String hasPets = request.getParameter("has_pets");
                if ("on".equals(hasPets)) {
                    adopter.setHasOtherPets(1);
                } else {
                    adopter.setHasOtherPets(0);
                }

                adopter.setNotes(request.getParameter("adopter_notes"));

                // Insert into adopter table
                boolean adopterCreated = usersDao.createAdopter(adopter, userId);

                if (adopterCreated) {
                    logger.info("Adopter created for user ID: " + userId);
                    message = "🎉 Adopter account successfully created! Welcome to our community!";
                    redirectPage = "login.jsp";
                    registrationSuccess = true;
                }
            }

            if (registrationSuccess) {
                conn.commit();

                // Encode message untuk URL
                String encodedMessage = java.net.URLEncoder.encode(message, "UTF-8");

                // Redirect ke register.jsp dengan success parameters
                response.sendRedirect("register.jsp?success=" + encodedMessage + "&role=" + role);
            } else {
                conn.rollback();
                message = "Registration failed. Please try again.";
                request.setAttribute("errorMessage", message);
                request.getRequestDispatcher("register.jsp").forward(request, response);
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Database error during registration", e);
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    logger.log(Level.SEVERE, "Error during rollback", ex);
                }
            }
            message = "Registration failed due to database error: " + e.getMessage();
            request.setAttribute("errorMessage", message);
            request.getRequestDispatcher("register.jsp").forward(request, response);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Unexpected error during registration", e);
            message = "Unexpected error: " + e.getMessage();
            request.setAttribute("errorMessage", message);
            request.getRequestDispatcher("register.jsp").forward(request, response);
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException e) {
                    logger.log(Level.WARNING, "Failed to close connection", e);
                }
            }
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Redirect to register page jika accessed via GET
        response.sendRedirect("register.jsp");
    }
}
