package com.rimba.adopt.controller;

import com.rimba.adopt.dao.UsersDao;
import com.rimba.adopt.model.Users;
import com.rimba.adopt.util.SessionUtil;
import com.rimba.adopt.util.DatabaseConnection;
import java.io.*;
import java.sql.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.UUID;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.servlet.*;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;

@WebServlet("/AuthServlet")
public class AuthServlet extends HttpServlet {

    private static final Logger logger = Logger.getLogger(AuthServlet.class.getName());

    // ========== SAME HASH METHOD AS REGISTRATION ==========
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

    // ========== GENERATE RANDOM TOKEN ==========
    private String generateResetToken() {
        // Contoh: "a1b2c3d4-1234567890"
        return UUID.randomUUID().toString() + "-" + System.currentTimeMillis();
    }

    // ========== DO POST METHOD ==========
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        request.setCharacterEncoding("UTF-8");
        response.setContentType("text/html; charset=UTF-8");

        String action = request.getParameter("action");

        if (action == null) {
            response.sendRedirect("login.jsp?error=No_action_specified");
            return;
        }

        switch (action) {
            case "login":
                handleLogin(request, response);
                break;
            case "logout":
                handleLogout(request, response);
                break;
            case "requestReset":
                handlePasswordResetRequest(request, response);
                break;
            case "resetPassword":
                handlePasswordReset(request, response);
                break;
            default:
                response.sendRedirect("login.jsp?error=Unknown_action");
        }
    }

    // ========== DO GET METHOD ==========
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // Untuk verify reset token (akses dari email link)
        String token = request.getParameter("token");

        if (token != null && !token.trim().isEmpty()) {
            verifyResetToken(token, request, response);
        } else {
            response.sendRedirect("login.jsp");
        }
    }

    // ========== HANDLE PASSWORD RESET REQUEST ==========
    private void handlePasswordResetRequest(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Get parameters from form
        String email = request.getParameter("email");
        String role = request.getParameter("role"); // admin, shelter, adopter

        logger.info("Password reset request for email: " + email + ", role: " + role);

        // 2. Validation
        if (email == null || email.trim().isEmpty()) {
            response.sendRedirect("login.jsp?error=Please_enter_your_email");
            return;
        }

        Connection conn = null;
        try {
            // 3. Get database connection
            conn = DatabaseConnection.getConnection();
            UsersDao usersDao = new UsersDao(conn);

            // 4. Check if user exists with this email
            Users user = usersDao.getUserByEmail(email);

            // 5. Security: Always show same message whether user exists or not
            // Ini untuk prevent email enumeration attack
            if (user == null) {
                logger.info("User not found with email: " + email);
                response.sendRedirect("login.jsp?message=If_your_email_exists_reset_instructions_will_be_sent");
                return;
            }

            // 6. Check if role matches
            if (!user.getRole().equals(role)) {
                logger.info("Role mismatch for email: " + email
                        + " (DB role: " + user.getRole() + ", Requested role: " + role + ")");
                response.sendRedirect("login.jsp?message=If_your_email_exists_reset_instructions_will_be_sent");
                return;
            }

            // 7. Generate reset token
            String resetToken = generateResetToken();

            // 8. Calculate expiry time (24 hours from now)
            long expiryMillis = System.currentTimeMillis() + (24 * 60 * 60 * 1000);
            Timestamp expiryTime = new Timestamp(expiryMillis);

            // 9. Save token to database
            String insertTokenSQL = "INSERT INTO password_reset_tokens (user_id, reset_token, expiry_time) "
                    + "VALUES (?, ?, ?)";

            try (PreparedStatement stmt = conn.prepareStatement(insertTokenSQL)) {
                stmt.setInt(1, user.getUserId());
                stmt.setString(2, resetToken);
                stmt.setTimestamp(3, expiryTime);

                int rows = stmt.executeUpdate();
                logger.info("Reset token saved for user ID: " + user.getUserId()
                        + ", Rows affected: " + rows);
            }

            // 10. Generate reset link (FOR DEVELOPMENT - we'll log it)
            // In production, you would send this via email
            String appUrl = getAppUrl(request);
            String resetLink = appUrl + "/reset_password.jsp?token=" + resetToken;

            // 11. LOG THE LINK (for testing)
            logger.info("=== PASSWORD RESET LINK ===");
            logger.info("For user: " + user.getName() + " (" + email + ")");
            logger.info("Reset Link: " + resetLink);
            logger.info("Token: " + resetToken);
            logger.info("Expires: " + expiryTime);
            logger.info("===========================");

            // 12. Redirect with success message
            response.sendRedirect("login.jsp?message=Reset_instructions_have_been_sent_to_your_email");

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Database error in password reset request", e);
            response.sendRedirect("login.jsp?error=Database_error_please_try_again");
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Unexpected error in password reset request", e);
            response.sendRedirect("login.jsp?error=System_error_please_try_again");
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException e) {
                }
            }
        }
    }

    // ========== VERIFY RESET TOKEN (GET REQUEST) ==========
    private void verifyResetToken(String token, HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();

            // 1. Check if token exists and is valid
            String checkTokenSQL = "SELECT user_id FROM password_reset_tokens "
                    + "WHERE reset_token = ? AND used = 0 AND expiry_time > CURRENT_TIMESTAMP";

            try (PreparedStatement stmt = conn.prepareStatement(checkTokenSQL)) {
                stmt.setString(1, token);
                ResultSet rs = stmt.executeQuery();

                if (rs.next()) {
                    // Token is valid - redirect to reset password page
                    logger.info("Token is valid, redirecting to reset password page");
                    response.sendRedirect("reset_password.jsp?token=" + token);
                } else {
                    // Token is invalid or expired
                    logger.warning("Invalid or expired token: " + token);
                    response.sendRedirect("login.jsp?error=Invalid_or_expired_reset_link");
                }
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Database error verifying token", e);
            response.sendRedirect("login.jsp?error=Database_error");
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException e) {
                }
            }
        }
    }

    // ========== HANDLE PASSWORD RESET (SET NEW PASSWORD) ==========
    private void handlePasswordReset(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1. Get parameters
        String token = request.getParameter("token");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        logger.info("Password reset attempt with token: " + token);

        // 2. Basic validation
        if (token == null || newPassword == null || confirmPassword == null) {
            response.sendRedirect("login.jsp?error=Missing_required_fields");
            return;
        }

        if (!newPassword.equals(confirmPassword)) {
            response.sendRedirect("reset_password.jsp?token=" + token + "&error=Passwords_do_not_match");
            return;
        }

        if (newPassword.length() < 6) {
            response.sendRedirect("reset_password.jsp?token=" + token + "&error=Password_must_be_at_least_6_characters");
            return;
        }

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false); // Start transaction

            // 3. Check token validity and get user_id
            String getTokenSQL = "SELECT user_id FROM password_reset_tokens "
                    + "WHERE reset_token = ? AND used = 0 AND expiry_time > CURRENT_TIMESTAMP";

            Integer userId = null;
            try (PreparedStatement stmt = conn.prepareStatement(getTokenSQL)) {
                stmt.setString(1, token);
                ResultSet rs = stmt.executeQuery();
                if (rs.next()) {
                    userId = rs.getInt("user_id");
                    logger.info("Valid token found for user ID: " + userId);
                }
            }

            // 4. If token invalid
            if (userId == null) {
                conn.rollback();
                logger.warning("Invalid token or already used: " + token);
                response.sendRedirect("login.jsp?error=Invalid_or_expired_reset_link");
                return;
            }

            // 5. Hash the new password
            String hashedPassword = hashPassword(newPassword);
            if (hashedPassword == null) {
                conn.rollback();
                response.sendRedirect("reset_password.jsp?token=" + token + "&error=System_error_hashing_password");
                return;
            }

            // 6. Update user's password
            String updatePasswordSQL = "UPDATE users SET password = ? WHERE user_id = ?";
            try (PreparedStatement stmt = conn.prepareStatement(updatePasswordSQL)) {
                stmt.setString(1, hashedPassword);
                stmt.setInt(2, userId);
                int rowsUpdated = stmt.executeUpdate();
                logger.info("Password updated for user ID " + userId + ", Rows: " + rowsUpdated);
            }

            // 7. Mark token as used
            String markTokenUsedSQL = "UPDATE password_reset_tokens SET used = 1 WHERE reset_token = ?";
            try (PreparedStatement stmt = conn.prepareStatement(markTokenUsedSQL)) {
                stmt.setString(1, token);
                stmt.executeUpdate();
                logger.info("Token marked as used: " + token);
            }

            // 8. Commit transaction
            conn.commit();
            logger.info("Password reset completed successfully for user ID: " + userId);

            // 9. Redirect to login with success message
            response.sendRedirect("login.jsp?message=Password_has_been_reset_successfully");

        } catch (SQLException e) {
            try {
                if (conn != null) {
                    conn.rollback();
                }
            } catch (SQLException ex) {
            }
            logger.log(Level.SEVERE, "Database error during password reset", e);
            response.sendRedirect("reset_password.jsp?token=" + token + "&error=Database_error");
        } catch (Exception e) {
            try {
                if (conn != null) {
                    conn.rollback();
                }
            } catch (SQLException ex) {
            }
            logger.log(Level.SEVERE, "Unexpected error during password reset", e);
            response.sendRedirect("reset_password.jsp?token=" + token + "&error=System_error");
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException e) {
                }
            }
        }
    }

    // ========== HELPER METHOD: GET APPLICATION URL ==========
    private String getAppUrl(HttpServletRequest request) {
        // Build application URL
        String scheme = request.getScheme();             // http
        String serverName = request.getServerName();     // localhost
        int serverPort = request.getServerPort();        // 8080
        String contextPath = request.getContextPath();   // /RimbaPetAdoptionSystem

        String url = scheme + "://" + serverName;

        // Add port if not default
        if (("http".equals(scheme) && serverPort != 80)
                || ("https".equals(scheme) && serverPort != 443)) {
            url += ":" + serverPort;
        }

        url += contextPath;

        return url;
    }

    // ========== HANDLE LOGIN ==========
    private void handleLogin(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String roleParam = request.getParameter("role"); // dari radio button

        logger.info("Login attempt - Email: " + email + ", Role: " + roleParam);

        // Validation
        if (email == null || password == null || email.trim().isEmpty()) {
            response.sendRedirect("login.jsp?error=Email_and_password_required");
            return;
        }

        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            UsersDao usersDao = new UsersDao(conn);

            // 1. Get user by email
            Users user = usersDao.getUserByEmail(email);

            if (user == null) {
                response.sendRedirect("login.jsp?error=Invalid_credentials");
                return;
            }

            // 2. Verify password (hash input password)
            String hashedInput = hashPassword(password);
            if (hashedInput == null || !hashedInput.equals(user.getPassword())) {
                response.sendRedirect("login.jsp?error=Invalid_credentials");
                return;
            }

            // 3. Verify role matches (role dari form VS role dari database)
            if (!user.getRole().equals(roleParam)) {
                response.sendRedirect("login.jsp?error=Invalid_role_for_account");
                return;
            }

            // 4. Special check for shelter - perlu approved
            if ("shelter".equals(user.getRole())) {
                String shelterCheckSql = "SELECT approval_status FROM shelter WHERE shelter_id = ?";
                try (PreparedStatement stmt = conn.prepareStatement(shelterCheckSql)) {
                    stmt.setInt(1, user.getUserId());
                    ResultSet rs = stmt.executeQuery();
                    if (rs.next()) {
                        String status = rs.getString("approval_status");
                        if (!"approved".equals(status)) {
                            response.sendRedirect("login.jsp?error=Shelter_not_approved_yet");
                            return;
                        }
                    } else {
                        response.sendRedirect("login.jsp?error=Shelter_not_found");
                        return;
                    }
                }
            }

            // 5. Create session menggunakan SessionUtil
            SessionUtil.setUserSession(request.getSession(), user);

            // 6. Redirect based on role
            switch (user.getRole()) {
                case "admin":
                    response.sendRedirect("dashboard_admin.jsp");
                    break;
                case "shelter":
                    response.sendRedirect("dashboard_shelter.jsp");
                    break;
                case "adopter":
                    response.sendRedirect("dashboard_adopter.jsp");
                    break;
                default:
                    response.sendRedirect("login.jsp?error=Invalid_role");
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Database error during login", e);
            response.sendRedirect("login.jsp?error=Database_error");
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Unexpected error during login", e);
            response.sendRedirect("login.jsp?error=System_error");
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException e) {
                }
            }
        }
    }

    // ========== HANDLE LOGOUT ==========
    private void handleLogout(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        if (session != null) {
            // Log user info sebelum logout
            String userName = (String) session.getAttribute("userName");
            String userRole = (String) session.getAttribute("userRole");
            logger.info("Logout - User: " + userName + ", Role: " + userRole);

            // Invalidate session
            session.invalidate();
        }

        // Redirect ke login dengan success message
        response.sendRedirect("login.jsp?message=Logged_out_successfully");
    }
}
