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
        response.setContentType("application/json; charset=UTF-8");

        String action = request.getParameter("action");

        // ========== HANDLE APPROVE/REJECT ACTIONS ==========
        if ("approve".equals(action)) {
            handleApprove(request, response);
            return;
        }

        if ("reject".equals(action)) {
            handleReject(request, response);
            return;
        }

        if ("bulkApprove".equals(action)) {
            handleBulkApprove(request, response);
            return;
        }

        if ("bulkReject".equals(action)) {
            handleBulkReject(request, response);
            return;
        }

        // ========== EXISTING REGISTRATION CODE (keep as is) ==========
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

    // ========== HANDLE SINGLE APPROVE ==========
    private void handleApprove(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String shelterIdStr = request.getParameter("shelterId");
        String reason = request.getParameter("reason");

        if (shelterIdStr == null || shelterIdStr.isEmpty()) {
            response.getWriter().write("{\"success\":false,\"error\":\"Missing shelterId\"}");
            return;
        }

        Connection conn = null;
        try {
            int shelterId = Integer.parseInt(shelterIdStr);

            conn = DatabaseConnection.getConnection();

            // Get admin ID from session
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("userId") == null) {
                response.getWriter().write("{\"success\":false,\"error\":\"Not logged in\"}");
                return;
            }

            int adminId = (Integer) session.getAttribute("userId");

            UsersDao usersDao = new UsersDao(conn);
            boolean success = usersDao.approveShelter(shelterId, adminId, reason);

            if (success) {
                response.getWriter().write("{\"success\":true,\"message\":\"Shelter approved successfully\"}");
            } else {
                response.getWriter().write("{\"success\":false,\"error\":\"Failed to approve shelter\"}");
            }

        } catch (NumberFormatException e) {
            logger.log(Level.SEVERE, "Invalid shelterId format", e);
            response.getWriter().write("{\"success\":false,\"error\":\"Invalid shelter ID\"}");
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Database error during approval", e);
            response.getWriter().write("{\"success\":false,\"error\":\"Database error: " + e.getMessage() + "\"}");
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

// ========== HANDLE SINGLE REJECT ==========
    private void handleReject(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String shelterIdStr = request.getParameter("shelterId");
        String reason = request.getParameter("reason");

        if (shelterIdStr == null || shelterIdStr.isEmpty()) {
            response.getWriter().write("{\"success\":false,\"error\":\"Missing shelterId\"}");
            return;
        }

        if (reason == null || reason.trim().isEmpty()) {
            response.getWriter().write("{\"success\":false,\"error\":\"Rejection reason is required\"}");
            return;
        }

        Connection conn = null;
        try {
            int shelterId = Integer.parseInt(shelterIdStr);

            conn = DatabaseConnection.getConnection();

            // Get admin ID from session
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("userId") == null) {
                response.getWriter().write("{\"success\":false,\"error\":\"Not logged in\"}");
                return;
            }

            int adminId = (Integer) session.getAttribute("userId");

            UsersDao usersDao = new UsersDao(conn);
            boolean success = usersDao.rejectShelter(shelterId, adminId, reason);

            if (success) {
                response.getWriter().write("{\"success\":true,\"message\":\"Shelter rejected successfully\"}");
            } else {
                response.getWriter().write("{\"success\":false,\"error\":\"Failed to reject shelter\"}");
            }

        } catch (NumberFormatException e) {
            logger.log(Level.SEVERE, "Invalid shelterId format", e);
            response.getWriter().write("{\"success\":false,\"error\":\"Invalid shelter ID\"}");
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Database error during rejection", e);
            response.getWriter().write("{\"success\":false,\"error\":\"Database error: " + e.getMessage() + "\"}");
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

// ========== HANDLE BULK APPROVE ==========
    private void handleBulkApprove(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String[] shelterIds = request.getParameterValues("shelterIds[]");
        String reason = request.getParameter("reason");

        if (shelterIds == null || shelterIds.length == 0) {
            response.getWriter().write("{\"success\":false,\"error\":\"No shelters selected\"}");
            return;
        }

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            // Get admin ID from session
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("userId") == null) {
                response.getWriter().write("{\"success\":false,\"error\":\"Not logged in\"}");
                return;
            }

            int adminId = (Integer) session.getAttribute("userId");

            UsersDao usersDao = new UsersDao(conn);
            int successCount = 0;

            for (String shelterIdStr : shelterIds) {
                try {
                    int shelterId = Integer.parseInt(shelterIdStr);
                    if (usersDao.approveShelter(shelterId, adminId, reason)) {
                        successCount++;
                    }
                } catch (NumberFormatException e) {
                    logger.log(Level.WARNING, "Invalid shelterId in bulk approve: " + shelterIdStr, e);
                }
            }

            conn.commit();

            response.getWriter().write("{\"success\":true,\"count\":" + successCount + "}");

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Database error during bulk approval", e);
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    logger.log(Level.SEVERE, "Error during rollback", ex);
                }
            }
            response.getWriter().write("{\"success\":false,\"error\":\"Database error: " + e.getMessage() + "\"}");
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    logger.log(Level.WARNING, "Failed to close connection", e);
                }
            }
        }
    }

// ========== HANDLE BULK REJECT ==========
    private void handleBulkReject(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String[] shelterIds = request.getParameterValues("shelterIds[]");
        String reason = request.getParameter("reason");

        if (shelterIds == null || shelterIds.length == 0) {
            response.getWriter().write("{\"success\":false,\"error\":\"No shelters selected\"}");
            return;
        }

        if (reason == null || reason.trim().isEmpty()) {
            response.getWriter().write("{\"success\":false,\"error\":\"Rejection reason is required\"}");
            return;
        }

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            // Get admin ID from session
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("userId") == null) {
                response.getWriter().write("{\"success\":false,\"error\":\"Not logged in\"}");
                return;
            }

            int adminId = (Integer) session.getAttribute("userId");

            UsersDao usersDao = new UsersDao(conn);
            int successCount = 0;

            for (String shelterIdStr : shelterIds) {
                try {
                    int shelterId = Integer.parseInt(shelterIdStr);
                    if (usersDao.rejectShelter(shelterId, adminId, reason)) {
                        successCount++;
                    }
                } catch (NumberFormatException e) {
                    logger.log(Level.WARNING, "Invalid shelterId in bulk reject: " + shelterIdStr, e);
                }
            }

            conn.commit();

            response.getWriter().write("{\"success\":true,\"count\":" + successCount + "}");

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Database error during bulk rejection", e);
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    logger.log(Level.SEVERE, "Error during rollback", ex);
                }
            }
            response.getWriter().write("{\"success\":false,\"error\":\"Database error: " + e.getMessage() + "\"}");
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
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

        String action = request.getParameter("action");

        // Handle API requests untuk review_registrations.jsp
        if ("getRegistrations".equals(action)) {
            handleGetRegistrations(request, response);
            return;
        }

        if ("getStatistics".equals(action)) {
            handleGetStatistics(request, response);
            return;
        }

        // Default: redirect to register page
        response.sendRedirect("register.jsp");
    }

    // ========== HANDLE GET REGISTRATIONS FOR FRONTEND ==========
    private void handleGetRegistrations(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            UsersDao usersDao = new UsersDao(conn);

            // Get all registrations
            java.util.List<java.util.Map<String, Object>> registrations = usersDao.getAllRegistrationsForReview();

            // Convert to JSON manually (simple approach)
            StringBuilder json = new StringBuilder("[");

            for (int i = 0; i < registrations.size(); i++) {
                java.util.Map<String, Object> reg = registrations.get(i);

                if (i > 0) {
                    json.append(",");
                }

                json.append("{");
                json.append("\"id\":\"").append(escapeJson(String.valueOf(reg.get("id")))).append("\",");
                json.append("\"userId\":").append(reg.get("userId")).append(",");
                json.append("\"name\":\"").append(escapeJson(String.valueOf(reg.get("name")))).append("\",");
                json.append("\"email\":\"").append(escapeJson(String.valueOf(reg.get("email")))).append("\",");
                json.append("\"type\":\"").append(escapeJson(String.valueOf(reg.get("type")))).append("\",");
                json.append("\"date\":\"").append(escapeJson(String.valueOf(reg.get("date")))).append("\",");
                json.append("\"status\":\"").append(escapeJson(String.valueOf(reg.get("status")))).append("\",");

                // Details object
                json.append("\"details\":{");
                json.append("\"contactPerson\":\"").append(escapeJson(String.valueOf(reg.get("name")))).append("\",");
                json.append("\"phone\":\"").append(escapeJson(String.valueOf(reg.getOrDefault("phone", "")))).append("\",");
                json.append("\"address\":\"").append(escapeJson(String.valueOf(reg.getOrDefault("address", "")))).append("\",");
                json.append("\"description\":\"").append(escapeJson(String.valueOf(reg.getOrDefault("description", "")))).append("\",");
                json.append("\"occupation\":\"").append(escapeJson(String.valueOf(reg.getOrDefault("occupation", "")))).append("\",");
                json.append("\"homeType\":\"").append(escapeJson(String.valueOf(reg.getOrDefault("householdType", "")))).append("\",");
                json.append("\"reason\":\"Looking to adopt a pet\"");
                json.append("},");

                // Approval/Rejection info
                String rejectionReason = String.valueOf(reg.getOrDefault("rejectionReason", ""));
                String approvalReason = String.valueOf(reg.getOrDefault("approvalMessage", ""));

                json.append("\"rejectionReason\":\"").append(escapeJson(rejectionReason.equals("null") ? "" : rejectionReason)).append("\",");
                json.append("\"approvalReason\":\"").append(escapeJson(approvalReason.equals("null") ? "" : approvalReason)).append("\"");

                json.append("}");
            }

            json.append("]");

            response.getWriter().write(json.toString());

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error fetching registrations", e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("{\"error\":\"Failed to load registrations\"}");
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

// ========== HANDLE GET STATISTICS FOR FRONTEND ==========
    private void handleGetStatistics(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            UsersDao usersDao = new UsersDao(conn);

            // Get statistics
            java.util.Map<String, Object> stats = usersDao.getApprovalStatistics();

            // Convert to JSON manually
            StringBuilder json = new StringBuilder("{");
            json.append("\"pendingCount\":").append(stats.getOrDefault("pendingCount", 0)).append(",");
            json.append("\"approvedToday\":").append(stats.getOrDefault("approvedToday", 0)).append(",");
            json.append("\"rejectedToday\":").append(stats.getOrDefault("rejectedToday", 0)).append(",");
            json.append("\"totalApproved\":").append(stats.getOrDefault("totalApproved", 0)).append(",");
            json.append("\"totalRejected\":").append(stats.getOrDefault("totalRejected", 0)).append(",");
            json.append("\"rejectionRate\":").append(stats.getOrDefault("rejectionRate", 0));
            json.append("}");

            response.getWriter().write(json.toString());

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error fetching statistics", e);
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("{\"error\":\"Failed to load statistics\"}");
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

// ========== HELPER: ESCAPE JSON STRINGS ==========
    private String escapeJson(String value) {
        if (value == null || value.equals("null")) {
            return "";
        }
        return value.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }
}
