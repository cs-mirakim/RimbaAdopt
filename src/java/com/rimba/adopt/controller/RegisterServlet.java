package com.rimba.adopt.controller;

import com.rimba.adopt.dao.UserDao;
import com.rimba.adopt.util.dbConnection;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.*;
import javax.servlet.annotation.MultipartConfig;

import java.io.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.*;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;

@WebServlet(name = "RegisterServlet", urlPatterns = {"/register"})
@MultipartConfig(
        maxFileSize = 2097152, // 2MB
        maxRequestSize = 5242880, // 5MB
        fileSizeThreshold = 1048576 // 1MB
)
public class RegisterServlet extends HttpServlet {

    private static final String UPLOAD_DIR = "profile_picture";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String role = request.getParameter("reg_role");
        String name = request.getParameter("full_name");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirm_password");
        String phone = request.getParameter("phone");

        // Validation
        if (role == null || name == null || email == null || password == null) {
            request.setAttribute("errorMessage", "All required fields must be filled");
            request.getRequestDispatcher("register.jsp").forward(request, response);
            return;
        }

        // Check password match
        if (!password.equals(confirmPassword)) {
            request.setAttribute("errorMessage", "Password and Confirm Password do not match");
            request.getRequestDispatcher("register.jsp").forward(request, response);
            return;
        }

        // Check password length
        if (password.length() < 6) {
            request.setAttribute("errorMessage", "Password must be at least 6 characters");
            request.getRequestDispatcher("register.jsp").forward(request, response);
            return;
        }

        try {
            UserDao userDao = new UserDao();

            // Check if email already exists
            if (userDao.checkEmailExists(email)) {
                request.setAttribute("errorMessage", "Email already registered");
                request.getRequestDispatcher("register.jsp").forward(request, response);
                return;
            }

            // Hash password
            String hashedPassword = hashPassword(password);

            // Handle file upload
            Part filePart = request.getPart("profile_photo");
            String profilePhotoPath = null;

            if (filePart != null && filePart.getSize() > 0) {
                profilePhotoPath = saveUploadedFile(filePart, role, email);
            } else {
                // Default profile picture based on role
                profilePhotoPath = "profile_picture/default_" + role + ".png";
            }

            // Create user based on role
            Integer userId = null;

            if ("adopter".equals(role)) {
                userId = registerAdopter(name, email, hashedPassword, phone, role, profilePhotoPath, request);
            } else if ("shelter".equals(role)) {
                userId = registerShelter(name, email, hashedPassword, phone, role, profilePhotoPath, request);
            }

            if (userId != null) {
                // Registration successful
                if ("adopter".equals(role)) {
                    request.setAttribute("successMessage", "Adopter account successfully created! You can now login.");
                } else {
                    request.setAttribute("successMessage", "Shelter registered! Please wait for admin approval.");
                }
                request.getRequestDispatcher("login.jsp").forward(request, response);
            } else {
                request.setAttribute("errorMessage", "Registration failed. Please try again.");
                request.getRequestDispatcher("register.jsp").forward(request, response);
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Registration error: " + e.getMessage());
            request.getRequestDispatcher("register.jsp").forward(request, response);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Redirect to registration page
        request.getRequestDispatcher("register.jsp").forward(request, response);
    }

    private String saveUploadedFile(Part filePart, String role, String email) throws IOException {
        // Get application path
        String appPath = getServletContext().getRealPath("");
        String uploadPath = appPath + File.separator + UPLOAD_DIR + File.separator + role;

        // Create directory if not exists
        File uploadDir = new File(uploadPath);
        if (!uploadDir.exists()) {
            uploadDir.mkdirs();
        }

        // Generate unique filename
        String fileName = extractFileName(filePart);
        String fileExtension = "";
        if (fileName.lastIndexOf(".") > 0) {
            fileExtension = fileName.substring(fileName.lastIndexOf("."));
        }
        String uniqueFileName = email.replace("@", "_") + "_" + System.currentTimeMillis() + fileExtension;

        // Save file
        String filePath = uploadPath + File.separator + uniqueFileName;

        InputStream input = null;
        OutputStream output = null;

        try {
            input = filePart.getInputStream();
            output = new FileOutputStream(new File(filePath));

            byte[] buffer = new byte[1024];
            int length;
            while ((length = input.read(buffer)) > 0) {
                output.write(buffer, 0, length);
            }
        } finally {
            if (output != null) {
                try {
                    output.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
            if (input != null) {
                try {
                    input.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }

        // Return relative path for database
        return UPLOAD_DIR + "/" + role + "/" + uniqueFileName;
    }

    private String extractFileName(Part part) {
        String contentDisp = part.getHeader("content-disposition");
        String[] items = contentDisp.split(";");
        for (String s : items) {
            if (s.trim().startsWith("filename")) {
                return s.substring(s.indexOf("=") + 2, s.length() - 1);
            }
        }
        return "";
    }

    private Integer registerShelter(String name, String email, String hashedPassword,
            String phone, String role, String profilePhotoPath,
            HttpServletRequest request) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmtUser = null;
        PreparedStatement pstmtShelter = null;
        ResultSet generatedKeys = null;

        try {
            conn = dbConnection.getConnection();
            conn.setAutoCommit(false); // Start transaction

            // Insert into users table
            String userSql = "INSERT INTO users (name, email, password, phone, role, profile_photo_path, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)";
            pstmtUser = conn.prepareStatement(userSql, PreparedStatement.RETURN_GENERATED_KEYS);
            pstmtUser.setString(1, name);
            pstmtUser.setString(2, email);
            pstmtUser.setString(3, hashedPassword);
            pstmtUser.setString(4, phone);
            pstmtUser.setString(5, role);
            pstmtUser.setString(6, profilePhotoPath);
            pstmtUser.setTimestamp(7, new Timestamp(System.currentTimeMillis()));

            int affectedRows = pstmtUser.executeUpdate();

            if (affectedRows == 0) {
                conn.rollback();
                return null;
            }

            // Get generated user_id
            Integer userId = null;
            generatedKeys = pstmtUser.getGeneratedKeys();
            if (generatedKeys.next()) {
                userId = generatedKeys.getInt(1);
            }

            if (userId == null) {
                conn.rollback();
                return null;
            }

            // Insert into shelter table
            String shelterSql = "INSERT INTO shelter (shelter_id, shelter_name, shelter_address, "
                    + "shelter_description, website, operating_hours, approval_status) "
                    + "VALUES (?, ?, ?, ?, ?, ?, ?)";
            pstmtShelter = conn.prepareStatement(shelterSql);
            pstmtShelter.setInt(1, userId);
            pstmtShelter.setString(2, request.getParameter("shelter_name"));
            pstmtShelter.setString(3, request.getParameter("shelter_address"));
            pstmtShelter.setString(4, request.getParameter("shelter_desc"));

            String website = request.getParameter("website");
            pstmtShelter.setString(5, (website != null && !website.trim().isEmpty()) ? website : null);

            // Format operating hours
            String hoursFrom = request.getParameter("hours_from");
            String hoursTo = request.getParameter("hours_to");
            String operatingHours = formatOperatingHours(hoursFrom, hoursTo);
            pstmtShelter.setString(6, operatingHours);

            pstmtShelter.setString(7, "pending"); // Default status

            pstmtShelter.executeUpdate();

            conn.commit(); // Commit transaction
            return userId;

        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException e1) {
                    e1.printStackTrace();
                }
            }
            throw e;
        } finally {
            // Close all resources
            if (pstmtShelter != null) {
                try {
                    pstmtShelter.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            if (pstmtUser != null) {
                try {
                    pstmtUser.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            if (generatedKeys != null) {
                try {
                    generatedKeys.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    // Contoh dalam registerAdopter method:
    private Integer registerAdopter(String name, String email, String hashedPassword,
            String phone, String role, String profilePhotoPath,
            HttpServletRequest request) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmtUser = null;
        PreparedStatement pstmtAdopter = null;
        ResultSet generatedKeys = null;

        try {
            conn = dbConnection.getConnection();
            conn.setAutoCommit(false); // Start transaction

            // Insert into users table
            String userSql = "INSERT INTO users (name, email, password, phone, role, profile_photo_path, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)";
            pstmtUser = conn.prepareStatement(userSql, PreparedStatement.RETURN_GENERATED_KEYS);
            pstmtUser.setString(1, name);
            pstmtUser.setString(2, email);
            pstmtUser.setString(3, hashedPassword);
            pstmtUser.setString(4, phone);
            pstmtUser.setString(5, role);
            pstmtUser.setString(6, profilePhotoPath);
            pstmtUser.setTimestamp(7, new Timestamp(System.currentTimeMillis()));

            int affectedRows = pstmtUser.executeUpdate();

            if (affectedRows == 0) {
                conn.rollback();
                return null;
            }

            // Get generated user_id - ES5 STYLE
            Integer userId = null;
            generatedKeys = pstmtUser.getGeneratedKeys();
            if (generatedKeys.next()) {
                userId = generatedKeys.getInt(1);
            }

            if (userId == null) {
                conn.rollback();
                return null;
            }

            // Insert into adopter table
            String adopterSql = "INSERT INTO adopter (adopter_id, address, occupation, household_type, has_other_pets, notes) VALUES (?, ?, ?, ?, ?, ?)";
            pstmtAdopter = conn.prepareStatement(adopterSql);
            pstmtAdopter.setInt(1, userId);
            pstmtAdopter.setString(2, request.getParameter("address"));
            pstmtAdopter.setString(3, request.getParameter("occupation"));
            pstmtAdopter.setString(4, request.getParameter("household"));

            // Handle has_other_pets checkbox
            String hasPetsStr = request.getParameter("has_pets");
            int hasOtherPets = (hasPetsStr != null && "on".equals(hasPetsStr)) ? 1 : 0;
            pstmtAdopter.setInt(5, hasOtherPets);

            String notes = request.getParameter("adopter_notes");
            pstmtAdopter.setString(6, notes != null ? notes : "");

            pstmtAdopter.executeUpdate();

            conn.commit(); // Commit transaction
            return userId;

        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException e1) {
                    e1.printStackTrace();
                }
            }
            throw e;
        } finally {
            // Close all resources - ES5 STYLE
            if (pstmtAdopter != null) {
                try {
                    pstmtAdopter.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            if (pstmtUser != null) {
                try {
                    pstmtUser.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            if (generatedKeys != null) {
                try {
                    generatedKeys.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    private String formatOperatingHours(String from, String to) {
        if (from == null || to == null) {
            return "N/A";
        }
        // Return dalam format 24-jam sahaja
        return from + " - " + to;
    }

    private String hashPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = md.digest(password.getBytes());

            StringBuilder hexString = new StringBuilder();
            for (byte hashByte : hashBytes) {
                String hex = Integer.toHexString(0xff & hashByte);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }
            return hexString.toString();

        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not found", e);
        }
    }
}
