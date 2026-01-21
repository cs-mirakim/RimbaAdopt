package com.rimba.adopt.controller;

import com.rimba.adopt.dao.AdoptionRequestDAO;
import com.rimba.adopt.dao.AdoptionRecordDAO;
import com.rimba.adopt.dao.FeedbackDAO;
import com.rimba.adopt.dao.PetsDAO;
import com.rimba.adopt.model.AdoptionRecord;
import com.rimba.adopt.model.AdoptionRequest;
import com.rimba.adopt.util.DatabaseConnection;
import com.rimba.adopt.util.SessionUtil;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
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
    private static final SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);

        // Check action parameter
        String action = request.getParameter("action");

        // ========== ACTION: VIEW PET INFO ==========
        if ("viewPetInfo".equals(action)) {
            String petIdStr = request.getParameter("id");

            if (petIdStr == null) {
                response.sendRedirect("index.jsp");
                return;
            }

            try {
                int petId = Integer.parseInt(petIdStr);
                Connection conn = DatabaseConnection.getConnection();

                try {
                    // Get pet with shelter info
                    PetsDAO petsDAO = new PetsDAO();
                    Map<String, Object> petData = petsDAO.getPetWithShelterInfo(petId);

                    if (petData == null) {
                        // Pet not found
                        request.setAttribute("error", "Pet not found or shelter not approved");
                        request.getRequestDispatcher("error.jsp").forward(request, response);
                        return;
                    }

                    // Get adoption request status if user is logged in
                    if (session != null) {
                        Integer userId = (Integer) session.getAttribute("userId");
                        String role = (String) session.getAttribute("role");

                        if (userId != null && "adopter".equals(role)) {
                            // Check if adopter has already applied for this pet
                            AdoptionRequestDAO requestDAO = new AdoptionRequestDAO();
                            List<Map<String, Object>> applications = requestDAO.getApplicationsByAdopter(userId);

                            for (Map<String, Object> app : applications) {
                                if (petId == (Integer) app.get("pet_id")) {
                                    request.setAttribute("hasApplied", true);
                                    request.setAttribute("applicationStatus", app.get("status"));
                                    break;
                                }
                            }
                        }
                    }

                    // Set attributes for JSP
                    request.setAttribute("petData", petData);

                    // Forward to pet_info.jsp
                    request.getRequestDispatcher("pet_info.jsp").forward(request, response);

                } finally {
                    DatabaseConnection.closeConnection(conn);
                }

            } catch (NumberFormatException e) {
                // Return JSON error instead of sendError
                logger.log(Level.WARNING, "Invalid parameters", e);

                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");

                PrintWriter out = response.getWriter();
                out.print("{\"success\": false, \"message\": \"Invalid parameters\"}");
                out.flush();

            } catch (SQLException e) {
                // Return JSON error instead of sendError
                logger.log(Level.SEVERE, "Error submitting adoption application", e);

                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");

                PrintWriter out = response.getWriter();
                out.print("{\"success\": false, \"message\": \"Database error: " + escapeJsonString(e.getMessage()) + "\"}");
                out.flush();
            }
            return;
        }

        // ========== ACTION: GET ADOPTER APPLICATIONS (JSON) ==========
        if ("getAdopterApplications".equals(action)) {
            // Authentication check for adopter
            if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isAdopter(session)) {
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized");
                return;
            }

            int adopterId = SessionUtil.getUserId(session);
            Connection conn = null;

            try {
                conn = DatabaseConnection.getConnection();
                AdoptionRequestDAO requestDAO = new AdoptionRequestDAO();

                List<Map<String, Object>> applications = requestDAO.getApplicationsByAdopter(adopterId);

                // Create JSON manually tanpa library
                StringBuilder jsonBuilder = new StringBuilder();
                jsonBuilder.append("[");

                boolean first = true;
                for (Map<String, Object> app : applications) {
                    if (!first) {
                        jsonBuilder.append(",");
                    }
                    first = false;

                    jsonBuilder.append("{");

                    boolean firstField = true;
                    for (Map.Entry<String, Object> entry : app.entrySet()) {
                        if (!firstField) {
                            jsonBuilder.append(",");
                        }
                        firstField = false;

                        String key = entry.getKey();
                        Object value = entry.getValue();

                        jsonBuilder.append("\"").append(key).append("\":");

                        if (value == null) {
                            jsonBuilder.append("null");
                        } else if (value instanceof String) {
                            // Escape special characters in string
                            String escapedValue = escapeJsonString((String) value);
                            jsonBuilder.append("\"").append(escapedValue).append("\"");
                        } else if (value instanceof Number) {
                            jsonBuilder.append(value);
                        } else if (value instanceof Boolean) {
                            jsonBuilder.append(value);
                        } else if (value instanceof Date) {
                            String dateStr = dateFormat.format((Date) value);
                            jsonBuilder.append("\"").append(dateStr).append("\"");
                        } else if (value instanceof java.sql.Timestamp) {
                            Date date = new Date(((java.sql.Timestamp) value).getTime());
                            String dateStr = dateFormat.format(date);
                            jsonBuilder.append("\"").append(dateStr).append("\"");
                        } else {
                            // Default to string representation
                            jsonBuilder.append("\"").append(escapeJsonString(value.toString())).append("\"");
                        }
                    }

                    jsonBuilder.append("}");
                }

                jsonBuilder.append("]");

                // Set response type
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");

                PrintWriter out = response.getWriter();
                out.print(jsonBuilder.toString());
                out.flush();

            } catch (SQLException e) {
                logger.log(Level.SEVERE, "Error getting adopter applications", e);
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error");
            } finally {
                DatabaseConnection.closeConnection(conn);
            }
            return;
        }

        // ========== ACTION: VIEW MONITOR APPLICATION PAGE ==========
        if ("viewMonitor".equals(action)) {
            // Authentication check for adopter
            if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isAdopter(session)) {
                response.sendRedirect("index.jsp");
                return;
            }

            // Forward to monitor_application.jsp
            request.getRequestDispatcher("monitor_application.jsp").forward(request, response);
            return;
        }

        // ========== ORIGINAL SHELTER LOGIC ==========
        // Authentication check for shelter
        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isShelter(session)) {
            response.sendRedirect("index.jsp");
            return;
        }

        int userId = SessionUtil.getUserId(session);

        Connection conn = null;

        try {
            conn = DatabaseConnection.getConnection();
            int shelterId = getShelterIdFromUserId(conn, userId);

            if ("view".equals(action)) {
                String requestIdStr = request.getParameter("id");
                if (requestIdStr != null) {
                    // Get request details AND set the full list
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
        String action = request.getParameter("action");

        // ========== ACTION: SUBMIT ADOPTION APPLICATION ==========
        if ("applyAdoption".equals(action)) {
            // Authentication check for adopter
            if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isAdopter(session)) {
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");

                PrintWriter out = response.getWriter();
                out.print("{\"success\": false, \"message\": \"Please login as adopter first\"}");
                out.flush();
                return;
            }

            String petIdStr = request.getParameter("petId");
            String shelterIdStr = request.getParameter("shelterId");
            String adopterMessage = request.getParameter("adopterMessage");

            if (petIdStr == null || shelterIdStr == null) {
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");

                PrintWriter out = response.getWriter();
                out.print("{\"success\": false, \"message\": \"Missing required parameters\"}");
                out.flush();
                return;
            }

            try {
                int petId = Integer.parseInt(petIdStr);
                int shelterId = Integer.parseInt(shelterIdStr);
                int adopterId = SessionUtil.getUserId(session);

                Connection conn = DatabaseConnection.getConnection();

                try {
                    // Create adoption request
                    AdoptionRequest adoptionRequest = new AdoptionRequest();
                    adoptionRequest.setAdopterId(adopterId);
                    adoptionRequest.setPetId(petId);
                    adoptionRequest.setShelterId(shelterId);
                    adoptionRequest.setAdopterMessage(adopterMessage);

                    AdoptionRequestDAO requestDAO = new AdoptionRequestDAO();
                    boolean success = requestDAO.createAdoptionRequest(adoptionRequest);

                    // Create JSON response manually
                    StringBuilder jsonBuilder = new StringBuilder();
                    jsonBuilder.append("{");

                    if (success) {
                        jsonBuilder.append("\"success\": true,");
                        jsonBuilder.append("\"message\": \"Adoption application submitted successfully!\"");
                    } else {
                        jsonBuilder.append("\"success\": false,");
                        jsonBuilder.append("\"message\": \"Cannot submit application. Pet may not be available or you already applied.\"");
                    }

                    jsonBuilder.append("}");

                    // Set response type
                    response.setContentType("application/json");
                    response.setCharacterEncoding("UTF-8");

                    PrintWriter out = response.getWriter();
                    out.print(jsonBuilder.toString());
                    out.flush();

                } finally {
                    DatabaseConnection.closeConnection(conn);
                }

            } catch (NumberFormatException e) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid parameters");
            } catch (SQLException e) {
                logger.log(Level.SEVERE, "Error submitting adoption application", e);
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error");
            }
            return;
        }

        // ========== ACTION: CANCEL ADOPTION REQUEST (ADOPTER) ==========
        if ("cancelAdopterRequest".equals(action)) {
            // Authentication check for adopter
            if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isAdopter(session)) {
                response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized");
                return;
            }

            int adopterId = SessionUtil.getUserId(session);
            String requestIdStr = request.getParameter("requestId");
            String cancellationReason = request.getParameter("cancellationReason");

            if (requestIdStr == null) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing request ID");
                return;
            }

            Connection conn = null;

            try {
                int requestId = Integer.parseInt(requestIdStr);
                conn = DatabaseConnection.getConnection();
                AdoptionRequestDAO requestDAO = new AdoptionRequestDAO();

                boolean success = requestDAO.cancelRequestByAdopter(requestId, adopterId, cancellationReason);

                // Create JSON response manually
                StringBuilder jsonBuilder = new StringBuilder();
                jsonBuilder.append("{");
                jsonBuilder.append("\"success\":").append(success).append(",");
                jsonBuilder.append("\"message\":\"").append(success ? "Application cancelled successfully" : "Failed to cancel application").append("\"");
                jsonBuilder.append("}");

                // Set response type
                response.setContentType("application/json");
                response.setCharacterEncoding("UTF-8");

                PrintWriter out = response.getWriter();
                out.print(jsonBuilder.toString());
                out.flush();

            } catch (NumberFormatException e) {
                logger.log(Level.WARNING, "Invalid request ID format", e);
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid request ID");
            } catch (SQLException e) {
                logger.log(Level.SEVERE, "Error cancelling adoption request", e);
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error");
            } finally {
                DatabaseConnection.closeConnection(conn);
            }
            return;
        }

        // ========== ORIGINAL SHELTER LOGIC ==========
        // Authentication check for shelter
        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isShelter(session)) {
            response.sendRedirect("index.jsp");
            return;
        }

        int userId = SessionUtil.getUserId(session);
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

    // Helper method to escape JSON strings
    private String escapeJsonString(String input) {
        if (input == null) {
            return "";
        }

        StringBuilder escaped = new StringBuilder();
        for (char c : input.toCharArray()) {
            switch (c) {
                case '"':
                    escaped.append("\\\"");
                    break;
                case '\\':
                    escaped.append("\\\\");
                    break;
                case '\b':
                    escaped.append("\\b");
                    break;
                case '\f':
                    escaped.append("\\f");
                    break;
                case '\n':
                    escaped.append("\\n");
                    break;
                case '\r':
                    escaped.append("\\r");
                    break;
                case '\t':
                    escaped.append("\\t");
                    break;
                default:
                    if (c < 0x20) {
                        escaped.append(String.format("\\u%04x", (int) c));
                    } else {
                        escaped.append(c);
                    }
            }
        }
        return escaped.toString();
    }

    // ========== NEW METHOD FOR DASHBOARD DATA ==========
    private DashboardData getDashboardData(Connection conn, int shelterId) throws SQLException {
        DashboardData data = new DashboardData();

        try {
            // Initialize DAOs
            PetsDAO petsDAO = new PetsDAO();
            AdoptionRequestDAO requestDAO = new AdoptionRequestDAO();
            FeedbackDAO feedbackDAO = new FeedbackDAO();

            // 1. Get total pets count
            data.setTotalPets(petsDAO.getPetCountByShelter(shelterId));

            // 2. Get adoption request counts by status
            Map<String, Integer> requestCounts = requestDAO.countRequestsByStatus(shelterId);
            data.setPendingRequests(requestCounts.getOrDefault("pending", 0));
            data.setApprovedRequests(requestCounts.getOrDefault("approved", 0));
            data.setRejectedRequests(requestCounts.getOrDefault("rejected", 0));
            data.setCancelledRequests(requestCounts.getOrDefault("cancelled", 0));

            // 3. Get average rating
            data.setAverageRating(feedbackDAO.getAverageRatingByShelterId(shelterId));

            // 4. Get monthly request statistics
            data.setMonthlyStats(requestDAO.getMonthlyRequestStats(shelterId));

            // 5. Get monthly feedback statistics
            data.setMonthlyFeedbackStats(feedbackDAO.getMonthlyFeedbackStats(shelterId));

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting dashboard data", e);
            throw e;
        }

        return data;
    }

    // ========== NEW INNER CLASS FOR DASHBOARD DATA ==========
    private static class DashboardData {

        private Integer totalPets;
        private Integer pendingRequests;
        private Integer approvedRequests;
        private Integer rejectedRequests;
        private Integer cancelledRequests;
        private Double averageRating;
        private Map<String, Object> monthlyStats;
        private Map<String, Object> monthlyFeedbackStats;

        // Getters and Setters
        public Integer getTotalPets() {
            return totalPets;
        }

        public void setTotalPets(Integer totalPets) {
            this.totalPets = totalPets;
        }

        public Integer getPendingRequests() {
            return pendingRequests;
        }

        public void setPendingRequests(Integer pendingRequests) {
            this.pendingRequests = pendingRequests;
        }

        public Integer getApprovedRequests() {
            return approvedRequests;
        }

        public void setApprovedRequests(Integer approvedRequests) {
            this.approvedRequests = approvedRequests;
        }

        public Integer getRejectedRequests() {
            return rejectedRequests;
        }

        public void setRejectedRequests(Integer rejectedRequests) {
            this.rejectedRequests = rejectedRequests;
        }

        public Integer getCancelledRequests() {
            return cancelledRequests;
        }

        public void setCancelledRequests(Integer cancelledRequests) {
            this.cancelledRequests = cancelledRequests;
        }

        public Double getAverageRating() {
            return averageRating;
        }

        public void setAverageRating(Double averageRating) {
            this.averageRating = averageRating;
        }

        public Map<String, Object> getMonthlyStats() {
            return monthlyStats;
        }

        public void setMonthlyStats(Map<String, Object> monthlyStats) {
            this.monthlyStats = monthlyStats;
        }

        public Map<String, Object> getMonthlyFeedbackStats() {
            return monthlyFeedbackStats;
        }

        public void setMonthlyFeedbackStats(Map<String, Object> monthlyFeedbackStats) {
            this.monthlyFeedbackStats = monthlyFeedbackStats;
        }
    }
}
