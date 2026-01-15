package com.rimba.adopt.controller;

import com.rimba.adopt.dao.AdoptionRequestDAO;
import com.rimba.adopt.dao.AdoptionRecordDAO;
import com.rimba.adopt.model.AdoptionRecord;
import com.rimba.adopt.util.DatabaseConnection;
import com.rimba.adopt.util.SessionUtil;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/ManageAdoptionRequest")
public class ManageAdoptionRequestServlet extends HttpServlet {

    private static final Logger logger = Logger.getLogger(ManageAdoptionRequestServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        // Authentication check
        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isShelter(session)) {
            response.sendRedirect("index.jsp");
            return;
        }

        int userId = SessionUtil.getUserId(session);
        String action = request.getParameter("action");

        Connection conn = null;

        try {
            conn = DatabaseConnection.getConnection();

            if ("view".equals(action)) {
                String requestIdStr = request.getParameter("id");
                if (requestIdStr != null) {
                    // Get request details AND set the full list
                    int shelterId = getShelterIdFromUserId(conn, userId);
                    AdoptionRequestDAO requestDAO = new AdoptionRequestDAO();

                    // MUST load full list also
                    List<Map<String, Object>> requests = requestDAO.getRequestsWithDetails(shelterId, "all", "");
                    request.setAttribute("requests", requests);
                    request.setAttribute("filter", "all");

                    // Forward instead of redirect
                    request.getRequestDispatcher("manage_request.jsp").forward(request, response);
                    return;  // IMPORTANT
                }
            } else {
                // List all requests for the shelter
                String filter = request.getParameter("filter");
                String search = request.getParameter("search");

                if (filter == null) {
                    filter = "all";
                }
                if (search == null) {
                    search = "";
                }

                // Get shelterId from users table
                int shelterId = getShelterIdFromUserId(conn, userId);

                // Get requests
                AdoptionRequestDAO requestDAO = new AdoptionRequestDAO();
                List<Map<String, Object>> requests = requestDAO.getRequestsWithDetails(shelterId, filter, search);

                // Get pending count
                int pendingCount = requestDAO.countPendingRequests(shelterId);

                // Set attributes for JSP
                request.setAttribute("requests", requests);
                request.setAttribute("filter", filter);
                request.setAttribute("search", search);
                request.setAttribute("pendingCount", pendingCount);
                request.setAttribute("shelterId", shelterId);

                // Forward to JSP
                request.getRequestDispatcher("manage_request.jsp").forward(request, response);
            }

        } catch (SQLException | NumberFormatException e) {
            logger.log(Level.SEVERE, "Error in ManageAdoptionRequestServlet doGet", e);
            request.setAttribute("error", "Database error: " + e.getMessage());
            request.getRequestDispatcher("error.jsp").forward(request, response);
        } finally {
            DatabaseConnection.closeConnection(conn);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        // Authentication check
        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isShelter(session)) {
            response.sendRedirect("index.jsp");
            return;
        }

        int userId = SessionUtil.getUserId(session);
        String action = request.getParameter("action");
        String requestIdStr = request.getParameter("requestId");
        String shelterResponse = request.getParameter("shelterResponse");

        if (requestIdStr == null || shelterResponse == null || shelterResponse.trim().isEmpty()) {
            // Set error in session untuk display di JSP
            session.setAttribute("message", "Please provide a response message");
            session.setAttribute("messageType", "error");
            response.sendRedirect("manage_request.jsp");
            return;
        }

        int requestId = Integer.parseInt(requestIdStr);
        Connection conn = null;

        try {
            conn = DatabaseConnection.getConnection();

            // Get shelterId from users table
            int shelterId = getShelterIdFromUserId(conn, userId);

            AdoptionRequestDAO requestDAO = new AdoptionRequestDAO();
            AdoptionRecordDAO recordDAO = new AdoptionRecordDAO();

            boolean success = false;

            if ("approve".equals(action)) {
                // APPROVE REQUEST
                success = requestDAO.approveRequest(requestId, shelterId, shelterResponse);

                if (success) {
                    // Get request details untuk dapat adopter_id dan pet_id
                    Map<String, Object> requestDetails = requestDAO.getRequestDetails(requestId, shelterId);

                    if (requestDetails != null) {
                        // Create adoption record
                        AdoptionRecord record = new AdoptionRecord();
                        record.setRequestId(requestId);
                        record.setAdopterId((Integer) requestDetails.get("adopter_id"));
                        record.setPetId((Integer) requestDetails.get("pet_id"));
                        record.setAdoptionDate(new java.sql.Date(new Date().getTime()));
                        record.setRemarks("Adoption approved by shelter");

                        recordDAO.createRecord(record);
                    }

                    session.setAttribute("message", "✓ Adoption request #" + requestId + " has been approved successfully.");
                    session.setAttribute("messageType", "success");
                } else {
                    session.setAttribute("message", "✗ Failed to approve request. It may have been processed already.");
                    session.setAttribute("messageType", "error");
                }

            } else if ("reject".equals(action)) {
                // REJECT REQUEST
                success = requestDAO.rejectRequest(requestId, shelterId, shelterResponse);

                if (success) {
                    session.setAttribute("message", "✓ Adoption request #" + requestId + " has been rejected.");
                    session.setAttribute("messageType", "success");
                } else {
                    session.setAttribute("message", "✗ Failed to reject request. It may have been processed already.");
                    session.setAttribute("messageType", "error");
                }
            } else {
                session.setAttribute("message", "✗ Invalid action specified");
                session.setAttribute("messageType", "error");
            }

            // Redirect back to manage requests page
            response.sendRedirect("manage_request.jsp");

        } catch (SQLException | NumberFormatException e) {
            logger.log(Level.SEVERE, "Error in ManageAdoptionRequestServlet doPost", e);
            session.setAttribute("message", "✗ Error: " + e.getMessage());
            session.setAttribute("messageType", "error");
            response.sendRedirect("manage_request.jsp");
        } finally {
            DatabaseConnection.closeConnection(conn);
        }
    }

    // Helper method to get shelter_id from user_id
    private int getShelterIdFromUserId(Connection conn, int userId) throws SQLException {
        // Since shelter.shelter_id = users.user_id, just return userId
        // But we should verify the user is actually a shelter
        String query = "SELECT COUNT(*) FROM shelter WHERE shelter_id = ?";

        try (PreparedStatement pstmt = conn.prepareStatement(query)) {
            pstmt.setInt(1, userId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    return userId; // User is a shelter
                }
            }
        }

        throw new SQLException("User is not a shelter or shelter not found");
    }
}
