package com.rimba.adopt.controller;

import com.rimba.adopt.dao.UsersDao;
import com.rimba.adopt.model.Users;
import com.rimba.adopt.model.Shelter;
import com.rimba.adopt.model.Adopter;
import com.rimba.adopt.util.DatabaseConnection;
import com.rimba.adopt.util.SessionUtil;
import java.io.*;
import java.sql.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.servlet.*;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize = 1024 * 1024 * 2,
        maxRequestSize = 1024 * 1024 * 5
)
@WebServlet("/ProfileServlet")
public class ProfileServlet extends HttpServlet {

    private static final Logger logger = Logger.getLogger(ProfileServlet.class.getName());

    // Password hashing - SAMA dengan RegistrationServlet
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
            return null;
        }
    }

    // Save profile photo - SAMA dengan RegistrationServlet
    private String saveProfilePhoto(Part filePart, HttpServletRequest request, String email, String role) throws IOException {
        if (filePart == null || filePart.getSize() == 0 || filePart.getSubmittedFileName() == null) {
            logger.info("No file uploaded or empty file");
            return null;
        }

        try {
            ServletContext context = request.getServletContext();
            String roleFolder = "profile_picture/" + role.toLowerCase() + "/";

            logger.info("=== FILE UPLOAD DEBUG START ===");
            logger.info("Role: " + role);
            logger.info("Email: " + email);
            logger.info("Original filename: " + filePart.getSubmittedFileName());
            logger.info("File size: " + filePart.getSize() + " bytes");

            // Webapp path
            String webappPath = context.getRealPath("");
            if (webappPath == null) {
                webappPath = "";
            }

            String fullWebappPath = webappPath;
            if (!fullWebappPath.endsWith(File.separator)) {
                fullWebappPath += File.separator;
            }
            fullWebappPath += "profile_picture" + File.separator + role.toLowerCase() + File.separator;

            // Project path
            String projectPath = "";
            try {
                File webappDir = new File(webappPath);
                File buildDir = webappDir.getParentFile();
                if (buildDir != null) {
                    File projectRoot = buildDir.getParentFile();
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
                projectPath = fullWebappPath;
            }

            logger.info("Webapp Path: " + fullWebappPath);
            logger.info("Project Path: " + projectPath);

            // Create directories
            File webappDir = new File(fullWebappPath);
            File projectDir = new File(projectPath);

            if (!webappDir.exists()) {
                webappDir.mkdirs();
            }
            if (!projectDir.exists()) {
                projectDir.mkdirs();
            }

            // Generate filename
            String originalFileName = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
            String fileExtension = "";
            int dotIndex = originalFileName.lastIndexOf('.');
            if (dotIndex > 0) {
                fileExtension = originalFileName.substring(dotIndex).toLowerCase();
            }

            String sanitizedEmail = email.replaceAll("[^a-zA-Z0-9._-]", "_");
            String fileName = sanitizedEmail + "_" + System.currentTimeMillis() + fileExtension;
            logger.info("Generated filename: " + fileName);

            // Save to both locations
            String webappFilePath = fullWebappPath + fileName;
            String projectFilePath = projectPath + fileName;

            boolean filesSaved = saveFileToMultipleLocations(filePart, webappFilePath, projectFilePath);
            logger.info("Files saved successfully: " + filesSaved);

            // Check files exist
            File webappFile = new File(webappFilePath);
            File projectFile = new File(projectFilePath);
            logger.info("Webapp file exists: " + webappFile.exists() + ", size: " + webappFile.length() + " bytes");
            logger.info("Project file exists: " + projectFile.exists() + ", size: " + projectFile.length() + " bytes");
            logger.info("=== FILE UPLOAD DEBUG END ===");

            return roleFolder + fileName;

        } catch (Exception e) {
            logger.log(Level.SEVERE, "Error in saveProfilePhoto method", e);
            return null;
        }
    }

    // Helper untuk save multiple locations - SAMA
    private boolean saveFileToMultipleLocations(Part filePart, String... filePaths) throws IOException {
        try (InputStream input = filePart.getInputStream()) {
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            byte[] buffer = new byte[1024];
            int bytesRead;
            while ((bytesRead = input.read(buffer)) != -1) {
                baos.write(buffer, 0, bytesRead);
            }
            byte[] fileData = baos.toByteArray();
            logger.info("File data read: " + fileData.length + " bytes");

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

    // Delete old profile photo
    private void deleteOldProfilePhoto(String profilePhotoPath, HttpServletRequest request) {
        if (profilePhotoPath == null || profilePhotoPath.isEmpty()) {
            return;
        }

        try {
            ServletContext context = request.getServletContext();
            String webappPath = context.getRealPath("");

            if (webappPath == null) {
                webappPath = "";
            }

            // Build full paths
            String webappFullPath = webappPath + File.separator + profilePhotoPath;

            // Build project path
            String projectPath = "";
            try {
                File webappDir = new File(webappPath);
                File buildDir = webappDir.getParentFile();
                if (buildDir != null) {
                    File projectRoot = buildDir.getParentFile();
                    if (projectRoot != null) {
                        projectPath = projectRoot.getAbsolutePath()
                                + File.separator + "web"
                                + File.separator + profilePhotoPath;
                    }
                }
            } catch (Exception e) {
                logger.log(Level.WARNING, "Could not build project path for deletion: " + e.getMessage());
                projectPath = webappFullPath;
            }

            // Delete from both locations
            File webappFile = new File(webappFullPath);
            File projectFile = new File(projectPath);

            if (webappFile.exists()) {
                boolean deleted = webappFile.delete();
                logger.info("Deleted webapp file: " + webappFullPath + ", Success: " + deleted);
            }

            if (projectFile.exists()) {
                boolean deleted = projectFile.delete();
                logger.info("Deleted project file: " + projectPath + ", Success: " + deleted);
            }

        } catch (Exception e) {
            logger.log(Level.WARNING, "Error deleting old profile photo", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Check login
        if (!SessionUtil.isLoggedIn(request.getSession())) {
            response.sendRedirect("login.jsp");
            return;
        }

        // Get user ID from session
        int userId = SessionUtil.getUserId(request.getSession());
        String userRole = SessionUtil.getUserRole(request.getSession());

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            UsersDao usersDao = new UsersDao(conn);

            // Get full profile data
            Map<String, Object> profileData = usersDao.getFullUserProfile(userId);

            if (profileData == null) {
                request.setAttribute("errorMessage", "User profile not found");
                request.getRequestDispatcher("profile.jsp").forward(request, response);
                return;
            }

            // Set attributes for JSP
            request.setAttribute("profileData", profileData);
            request.setAttribute("userRole", userRole);

            // Forward to profile.jsp
            request.getRequestDispatcher("profile.jsp").forward(request, response);

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Database error loading profile", e);
            request.setAttribute("errorMessage", "Database error: " + e.getMessage());
            request.getRequestDispatcher("profile.jsp").forward(request, response);
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Unexpected error loading profile", e);
            request.setAttribute("errorMessage", "System error: " + e.getMessage());
            request.getRequestDispatcher("profile.jsp").forward(request, response);
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
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html; charset=UTF-8");

        // Check login
        if (!SessionUtil.isLoggedIn(request.getSession())) {
            response.sendRedirect("login.jsp");
            return;
        }

        String action = request.getParameter("action");
        int userId = SessionUtil.getUserId(request.getSession());
        String userRole = SessionUtil.getUserRole(request.getSession());

        if (action == null) {
            response.sendRedirect("profile.jsp");
            return;
        }

        switch (action) {
            case "update":
                handleUpdateProfile(request, response, userId, userRole);
                break;
            case "delete":
                handleDeleteAccount(request, response, userId);
                break;
            default:
                response.sendRedirect("profile.jsp");
        }
    }

    private void handleUpdateProfile(HttpServletRequest request, HttpServletResponse response,
            int userId, String userRole) throws ServletException, IOException {

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false); // Start transaction

            UsersDao usersDao = new UsersDao(conn);

            // Get current user data
            Map<String, Object> currentData = usersDao.getFullUserProfile(userId);
            if (currentData == null) {
                throw new Exception("User profile not found");
            }

            Users currentUser = (Users) currentData.get("user");
            String oldProfilePhotoPath = currentUser.getProfilePhotoPath();

            // Handle profile photo upload
            Part filePart = request.getPart("profile_photo");
            String newProfilePhotoPath = null;

            if (filePart != null && filePart.getSize() > 0 && filePart.getSubmittedFileName() != null) {
                // Delete old photo jika ada
                if (oldProfilePhotoPath != null && !oldProfilePhotoPath.isEmpty()) {
                    deleteOldProfilePhoto(oldProfilePhotoPath, request);
                }

                // Save new photo
                newProfilePhotoPath = saveProfilePhoto(filePart, request, currentUser.getEmail(), userRole);
            }

            // Get form parameters
            String name = request.getParameter("name");
            String email = request.getParameter("email");
            String phone = request.getParameter("phone");
            String changePassword = request.getParameter("change_password");
            String newPassword = request.getParameter("new_password");
            String confirmPassword = request.getParameter("confirm_password");

            // Validate email uniqueness (if changed)
            if (!email.equals(currentUser.getEmail())) {
                if (usersDao.isEmailExists(email)) {
                    request.setAttribute("errorMessage", "Email already exists. Please use another email.");
                    request.getRequestDispatcher("profile.jsp").forward(request, response);
                    return;
                }
            }

            // Validate password if changing
            if ("on".equals(changePassword) && newPassword != null && !newPassword.isEmpty()) {
                if (!newPassword.equals(confirmPassword)) {
                    request.setAttribute("errorMessage", "New password and confirm password do not match.");
                    request.getRequestDispatcher("profile.jsp").forward(request, response);
                    return;
                }
                if (newPassword.length() < 6) {
                    request.setAttribute("errorMessage", "Password must be at least 6 characters.");
                    request.getRequestDispatcher("profile.jsp").forward(request, response);
                    return;
                }
            }

            // Update user object
            Users updatedUser = new Users();
            updatedUser.setUserId(userId);
            updatedUser.setName(name);
            updatedUser.setEmail(email);
            updatedUser.setPhone(phone);
            updatedUser.setRole(userRole);

            // Set profile photo path (new or keep old)
            if (newProfilePhotoPath != null) {
                updatedUser.setProfilePhotoPath(newProfilePhotoPath);
            } else {
                updatedUser.setProfilePhotoPath(oldProfilePhotoPath);
            }

            // Update password if changed
            if ("on".equals(changePassword) && newPassword != null && !newPassword.isEmpty()) {
                String hashedPassword = hashPassword(newPassword);
                if (hashedPassword != null) {
                    updatedUser.setPassword(hashedPassword);
                    usersDao.updatePassword(userId, hashedPassword);
                }
            }

            // Update users table
            boolean userUpdated = usersDao.updateUser(updatedUser);

            // Update role-specific data
            boolean roleUpdated = false;

            if ("shelter".equals(userRole)) {
                Shelter shelter = new Shelter();
                shelter.setShelterName(request.getParameter("shelter_name"));
                shelter.setShelterAddress(request.getParameter("shelter_address"));
                shelter.setShelterDescription(request.getParameter("shelter_description"));
                shelter.setWebsite(request.getParameter("website"));

                // Combine operating hours
                String hoursFrom = request.getParameter("hours_from");
                String hoursTo = request.getParameter("hours_to");
                if (hoursFrom != null && hoursTo != null
                        && !hoursFrom.trim().isEmpty() && !hoursTo.trim().isEmpty()) {
                    shelter.setOperatingHours(hoursFrom + " - " + hoursTo);
                } else {
                    shelter.setOperatingHours(request.getParameter("operating_hours"));
                }

                roleUpdated = usersDao.updateShelter(shelter, userId);

            } else if ("adopter".equals(userRole)) {
                Adopter adopter = new Adopter();
                adopter.setAddress(request.getParameter("address"));
                adopter.setOccupation(request.getParameter("occupation"));
                adopter.setHouseholdType(request.getParameter("household_type"));

                String hasPets = request.getParameter("has_other_pets");
                if ("on".equals(hasPets)) {
                    adopter.setHasOtherPets(1);
                } else {
                    adopter.setHasOtherPets(0);
                }

                adopter.setNotes(request.getParameter("notes"));
                roleUpdated = usersDao.updateAdopter(adopter, userId);

            } else if ("admin".equals(userRole)) {
                String position = request.getParameter("position");
                roleUpdated = usersDao.updateAdmin(position, userId);
            } else {
                roleUpdated = true; // No role-specific data to update
            }

            if (userUpdated && roleUpdated) {
                conn.commit();
                logger.info("Profile updated successfully for user ID: " + userId);

                // Update session dengan data baru
                HttpSession session = request.getSession();
                session.setAttribute("userName", updatedUser.getName());
                session.setAttribute("userEmail", updatedUser.getEmail());
                session.setAttribute("userProfilePhoto", updatedUser.getProfilePhotoPath());

                // Set success message
                request.setAttribute("successMessage", "Profile updated successfully!");

            } else {
                conn.rollback();
                logger.warning("Profile update failed for user ID: " + userId);
                request.setAttribute("errorMessage", "Failed to update profile. Please try again.");
            }

            // Reload updated data
            Map<String, Object> updatedProfileData = usersDao.getFullUserProfile(userId);
            request.setAttribute("profileData", updatedProfileData);
            request.setAttribute("userRole", userRole);

            // Forward back to profile page
            request.getRequestDispatcher("profile.jsp").forward(request, response);

        } catch (SQLException e) {
            try {
                if (conn != null) {
                    conn.rollback();
                }
            } catch (SQLException ex) {
                logger.log(Level.SEVERE, "Error during rollback", ex);
            }
            logger.log(Level.SEVERE, "Database error updating profile", e);
            request.setAttribute("errorMessage", "Database error: " + e.getMessage());
            request.getRequestDispatcher("profile.jsp").forward(request, response);

        } catch (Exception e) {
            try {
                if (conn != null) {
                    conn.rollback();
                }
            } catch (SQLException ex) {
                logger.log(Level.SEVERE, "Error during rollback", ex);
            }
            logger.log(Level.SEVERE, "Unexpected error updating profile", e);
            request.setAttribute("errorMessage", "System error: " + e.getMessage());
            request.getRequestDispatcher("profile.jsp").forward(request, response);

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

    private void handleDeleteAccount(HttpServletRequest request, HttpServletResponse response,
            int userId) throws ServletException, IOException {

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            UsersDao usersDao = new UsersDao(conn);

            // Get user info for file deletion
            Users user = usersDao.getUserById(userId);
            if (user == null) {
                request.setAttribute("errorMessage", "User not found");
                request.getRequestDispatcher("profile.jsp").forward(request, response);
                return;
            }

            // Delete profile photo jika ada
            if (user.getProfilePhotoPath() != null && !user.getProfilePhotoPath().isEmpty()) {
                deleteOldProfilePhoto(user.getProfilePhotoPath(), request);
            }

            // Delete user (cascade will handle related data)
            boolean deleted = usersDao.deleteUser(userId);

            if (deleted) {
                conn.commit();
                logger.info("Account deleted successfully for user ID: " + userId);

                // Invalidate session
                SessionUtil.invalidateSession(request.getSession());

                // Redirect to login with success message
                response.sendRedirect("login.jsp?message=Account_deleted_successfully");
                return;

            } else {
                conn.rollback();
                logger.warning("Account deletion failed for user ID: " + userId);
                request.setAttribute("errorMessage", "Failed to delete account. Please try again.");
                request.getRequestDispatcher("profile.jsp").forward(request, response);
            }

        } catch (SQLException e) {
            try {
                if (conn != null) {
                    conn.rollback();
                }
            } catch (SQLException ex) {
                logger.log(Level.SEVERE, "Error during rollback", ex);
            }
            logger.log(Level.SEVERE, "Database error deleting account", e);
            request.setAttribute("errorMessage", "Database error: " + e.getMessage());
            request.getRequestDispatcher("profile.jsp").forward(request, response);

        } catch (Exception e) {
            try {
                if (conn != null) {
                    conn.rollback();
                }
            } catch (SQLException ex) {
                logger.log(Level.SEVERE, "Error during rollback", ex);
            }
            logger.log(Level.SEVERE, "Unexpected error deleting account", e);
            request.setAttribute("errorMessage", "System error: " + e.getMessage());
            request.getRequestDispatcher("profile.jsp").forward(request, response);

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
}
