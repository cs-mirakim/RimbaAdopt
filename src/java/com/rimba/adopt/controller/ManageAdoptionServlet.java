package com.rimba.adopt.controller;

import com.rimba.adopt.dao.AdoptionRecordDAO;
import com.rimba.adopt.dao.AdoptionRequestDAO;
import com.rimba.adopt.model.AdoptionRecord;
import com.rimba.adopt.util.DatabaseConnection;
import com.rimba.adopt.util.SessionUtil;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/manageAdoptionServlet")
public class ManageAdoptionServlet extends HttpServlet {

    private AdoptionRequestDAO requestDAO;
    private AdoptionRecordDAO recordDAO;

    @Override
    public void init() throws ServletException {
        requestDAO = new AdoptionRequestDAO();
        recordDAO = new AdoptionRecordDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        // Check if user is logged in and is shelter
        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isShelter(session)) {
            response.sendRedirect("index.jsp");
            return;
        }

        int shelterId = SessionUtil.getUserId(session);

        try {
            // Get all adoption requests for this shelter with full details
            List<Map<String, Object>> requestsData = getRequestsWithDetails(shelterId);

            // Get pending count
            int pendingCount = requestDAO.getPendingCount(shelterId);

            // Get shelter name for display
            String shelterName = getShelterName(shelterId);

            // Set attributes for JSP
            request.setAttribute("requestsData", requestsData);
            request.setAttribute("pendingCount", pendingCount);
            request.setAttribute("shelterId", shelterId);
            request.setAttribute("shelterName", shelterName);

            // Forward to JSP
            request.getRequestDispatcher("manage_request.jsp").forward(request, response);

        } catch (SQLException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error");
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        // Debug 1: Log semua parameter yang diterima
        System.out.println("=== [DEBUG] ManageAdoptionServlet.doPost() STARTED ===");
        System.out.println("Received parameters:");
        Enumeration<String> paramNames = request.getParameterNames();
        while (paramNames.hasMoreElements()) {
            String paramName = paramNames.nextElement();
            String paramValue = request.getParameter(paramName);
            System.out.println("  " + paramName + " = " + paramValue);
        }

        // Check if user is logged in and is shelter
        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isShelter(session)) {
            System.out.println("[DEBUG] User not logged in or not shelter");
            response.sendRedirect("index.jsp");
            return;
        }

        int shelterId = SessionUtil.getUserId(session);
        System.out.println("[DEBUG] Shelter ID from session: " + shelterId);

        String action = request.getParameter("action");
        System.out.println("[DEBUG] Action parameter: " + action);

        try {
            if ("approve".equals(action) || "reject".equals(action)) {
                handleStatusUpdate(request, response, shelterId, action);
            } else {
                System.out.println("[ERROR] Invalid action parameter: " + action);
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid action: " + action);
            }

        } catch (SQLException e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error");
        } catch (NumberFormatException e) {
            System.out.println("[ERROR] Invalid requestId format: " + request.getParameter("requestId"));
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid request ID format");
        } catch (Exception e) {
            e.printStackTrace();
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Server error");
        }
    }

    // Helper method to get all requests with details
    private List<Map<String, Object>> getRequestsWithDetails(int shelterId) throws SQLException {
        List<Map<String, Object>> result = new ArrayList<>();

        String sql = "SELECT ar.request_id, ar.status, ar.request_date, ar.adopter_message, "
                + "ar.shelter_response, ar.cancellation_reason, "
                + "p.pet_id, p.name as pet_name, p.species as pet_species, p.breed as pet_breed, "
                + "p.age as pet_age, p.gender as pet_gender, p.health_status as pet_health, "
                + "p.photo_path as pet_photo, "
                + "u.user_id as adopter_id, u.name as adopter_name, u.email as adopter_email, "
                + "u.phone as adopter_phone, u.profile_photo_path as adopter_photo, "
                + "ad.occupation as adopter_occupation, ad.address as adopter_address, "
                + "ad.household_type, ad.has_other_pets, ad.notes as adopter_notes "
                + "FROM adoption_request ar "
                + "JOIN pets p ON ar.pet_id = p.pet_id "
                + "JOIN adopter ad ON ar.adopter_id = ad.adopter_id "
                + "JOIN users u ON ad.adopter_id = u.user_id "
                + "WHERE p.shelter_id = ? "
                + "ORDER BY ar.request_date DESC";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, shelterId);
            ResultSet rs = pstmt.executeQuery();

            while (rs.next()) {
                Map<String, Object> requestData = new HashMap<>();

                // Adoption request info
                requestData.put("id", rs.getInt("request_id"));
                requestData.put("status", rs.getString("status"));
                requestData.put("date", rs.getTimestamp("request_date"));
                requestData.put("adopter_message", rs.getString("adopter_message"));
                requestData.put("shelter_response", rs.getString("shelter_response"));
                requestData.put("cancellation_reason", rs.getString("cancellation_reason"));

                // Pet info
                requestData.put("pet", rs.getString("pet_name"));
                requestData.put("breed", rs.getString("pet_breed"));
                requestData.put("species", rs.getString("pet_species"));
                requestData.put("age", rs.getInt("pet_age") + " yrs");
                requestData.put("gender", rs.getString("pet_gender"));
                requestData.put("health", rs.getString("pet_health"));
                requestData.put("pet_img", rs.getString("pet_photo"));
                requestData.put("pet_id", rs.getInt("pet_id"));

                // Adopter info
                requestData.put("adopter", rs.getString("adopter_name"));
                requestData.put("job", rs.getString("adopter_occupation"));
                requestData.put("house", rs.getString("household_type"));
                requestData.put("pets", rs.getInt("has_other_pets") == 1);
                requestData.put("notes", rs.getString("adopter_notes"));
                requestData.put("adopter_email", rs.getString("adopter_email"));
                requestData.put("adopter_phone", rs.getString("adopter_phone"));
                requestData.put("adopter_img", rs.getString("adopter_photo"));
                requestData.put("adopter_id", rs.getInt("adopter_id"));
                requestData.put("adopter_address", rs.getString("adopter_address"));

                result.add(requestData);
            }
        }

        return result;
    }

    // Get shelter name for display
    private String getShelterName(int shelterId) throws SQLException {
        String sql = "SELECT shelter_name FROM shelter WHERE shelter_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, shelterId);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                return rs.getString("shelter_name");
            }
        }
        return "Shelter";
    }

    // Handle approve/reject actions
    // Handle approve/reject actions
    private void handleStatusUpdate(HttpServletRequest request, HttpServletResponse response,
            int shelterId, String action) throws SQLException, IOException {

        System.out.println("=== [DEBUG] handleStatusUpdate STARTED ===");
        System.out.println("Shelter ID: " + shelterId);
        System.out.println("Action: " + action);

        // Debug semua parameter
        System.out.println("All parameters in handleStatusUpdate:");
        Enumeration<String> paramNames = request.getParameterNames();
        while (paramNames.hasMoreElements()) {
            String paramName = paramNames.nextElement();
            String paramValue = request.getParameter(paramName);
            System.out.println("  " + paramName + " = " + paramValue);
        }

        String requestIdStr = request.getParameter("requestId");
        System.out.println("[DEBUG] requestId parameter (raw): " + requestIdStr);

        if (requestIdStr == null || requestIdStr.trim().isEmpty()) {
            System.out.println("[ERROR] requestId is null or empty");
            sendErrorResponse(response, "Request ID is required");
            return;
        }

        int requestId;
        try {
            requestId = Integer.parseInt(requestIdStr);
            System.out.println("[DEBUG] Parsed requestId: " + requestId);
        } catch (NumberFormatException e) {
            System.out.println("[ERROR] Cannot parse requestId: " + requestIdStr);
            sendErrorResponse(response, "Invalid request ID format");
            return;
        }

        String shelterResponse = request.getParameter("response");
        System.out.println("[DEBUG] Response parameter length: "
                + (shelterResponse != null ? shelterResponse.length() : "null"));

        if (shelterResponse == null || shelterResponse.trim().isEmpty()) {
            System.out.println("[ERROR] Shelter response is empty");
            sendErrorResponse(response, "Shelter response is required");
            return;
        }

        String newStatus = "approved".equals(action) ? "approved" : "rejected";
        System.out.println("[DEBUG] New status to set: " + newStatus);

        // Update the adoption request status
        System.out.println("[DEBUG] Calling requestDAO.updateRequestStatus...");
        boolean updated = requestDAO.updateRequestStatus(requestId, newStatus, shelterResponse, shelterId);
        System.out.println("[DEBUG] Update result: " + updated);

        if (updated) {
            // If approved, create adoption record
            if ("approved".equals(action)) {
                System.out.println("[DEBUG] Creating adoption record...");
                createAdoptionRecord(requestId, shelterResponse);
            }

            // Return success response
            response.setContentType("text/plain");
            PrintWriter out = response.getWriter();
            out.print("SUCCESS:" + newStatus + ":" + requestId);
            System.out.println("[DEBUG] Success response sent: SUCCESS:" + newStatus + ":" + requestId);

        } else {
            System.out.println("[ERROR] Update failed - request not found or no permission");
            sendErrorResponse(response, "Failed to update request. It may not exist or you don't have permission.");
        }
    }

    // Create adoption record for approved request
    private void createAdoptionRecord(int requestId, String remarks) throws SQLException {
        // First check if record already exists
        if (recordDAO.recordExists(requestId)) {
            return;
        }

        // Get request details to create record
        String sql = "SELECT adopter_id, pet_id FROM adoption_request WHERE request_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, requestId);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                AdoptionRecord record = new AdoptionRecord();
                record.setRequestId(requestId);
                record.setAdopterId(rs.getInt("adopter_id"));
                record.setPetId(rs.getInt("pet_id"));
                record.setAdoptionDate(new java.sql.Date(System.currentTimeMillis()));
                record.setRemarks(remarks);

                recordDAO.createRecord(record);
            }
        }
    }

    // Helper method to send error response
    private void sendErrorResponse(HttpServletResponse response, String message) throws IOException {
        response.setContentType("text/plain");
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        PrintWriter out = response.getWriter();
        out.print("ERROR:" + message);
    }
}
