package com.rimba.adopt.controller;

import com.rimba.adopt.dao.UserDao;
import com.rimba.adopt.model.Users;
import com.rimba.adopt.model.Admin;
import com.rimba.adopt.model.Adopter;
import com.rimba.adopt.model.Shelter;
import com.rimba.adopt.util.dbConnection;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.*;
import java.io.IOException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.sql.Connection;
import java.sql.SQLException;

@WebServlet(name = "LoginServlet", urlPatterns = {"/login"})
public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("login_email");
        String password = request.getParameter("login_password");
        String role = request.getParameter("role");

        // Validate inputs
        if (email == null || email.trim().isEmpty()
                || password == null || password.trim().isEmpty()
                || role == null) {

            request.setAttribute("errorMessage", "Please fill in all fields");
            request.getRequestDispatcher("login.jsp").forward(request, response);
            return;
        }

        // Hash password with SHA-256
        String hashedPassword = hashPassword(password);

        UserDao userDao = new UserDao();

        try {
            // Check user credentials
            Users user = userDao.authenticateUser(email, hashedPassword, role);

            if (user == null) {
                // Invalid credentials
                request.setAttribute("errorMessage", "Invalid email, password, or role");
                request.getRequestDispatcher("login.jsp").forward(request, response);
                return;
            }

            // **TAMBAH INI - Invalidate existing session and create new one**
            HttpSession oldSession = request.getSession(false);
            if (oldSession != null) {
                oldSession.invalidate();
            }
            HttpSession session = request.getSession(true); // Create new session
            // **AKHIR TAMBAHAN**

            // For shelter, check approval status
            if ("shelter".equals(role)) {
                Shelter shelter = userDao.getShelterDetails(user.getUserId());
                if (shelter == null || !"approved".equals(shelter.getApprovalStatus())) {
                    request.setAttribute("errorMessage",
                            "Shelter account is not approved. Please wait for admin approval.");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                    return;
                }

                // Store shelter-specific data in session
                session.setAttribute("shelterName", shelter.getShelterName());
                session.setAttribute("shelterAddress", shelter.getShelterAddress());
                session.setAttribute("approvalStatus", shelter.getApprovalStatus());
            }

            // For adopter, get adopter details
            if ("adopter".equals(role)) {
                Adopter adopter = userDao.getAdopterDetails(user.getUserId());
                if (adopter != null) {
                    session.setAttribute("address", adopter.getAddress());
                    session.setAttribute("occupation", adopter.getOccupation());
                    session.setAttribute("householdType", adopter.getHouseholdType());
                }
            }

            // For admin, get admin details
            if ("admin".equals(role)) {
                Admin admin = userDao.getAdminDetails(user.getUserId());
                if (admin != null) {
                    session.setAttribute("position", admin.getPosition());
                }
            }

            // Store common user data in session
            session.setAttribute("userId", user.getUserId());
            session.setAttribute("name", user.getName());
            session.setAttribute("email", user.getEmail());
            session.setAttribute("role", user.getRole());
            session.setAttribute("phone", user.getPhone());
            session.setAttribute("profilePhotoPath", user.getProfilePhotoPath());
            session.setAttribute("createdAt", user.getCreatedAt());

            // Set session timeout (optional, 30 minutes)
            session.setMaxInactiveInterval(30 * 60);

            // Redirect based on role
            String redirectPage = getDashboardPage(role);
            response.sendRedirect(redirectPage);

        } catch (SQLException e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Database error occurred. Please try again.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Redirect GET requests to login page
        response.sendRedirect("login.jsp");
    }

    private String hashPassword(String password) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] hashBytes = md.digest(password.getBytes());

            // Convert byte array to hexadecimal string
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

    private String getDashboardPage(String role) {
        switch (role) {
            case "admin":
                return "dashboard_admin.jsp";
            case "shelter":
                return "dashboard_shelter.jsp";
            case "adopter":
                return "dashboard_adopter.jsp";
            default:
                return "login.jsp";
        }
    }
}
