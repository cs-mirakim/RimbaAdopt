package com.rimba.adopt.controller;

import com.rimba.adopt.dao.AdoptionRequestDAO;
import com.rimba.adopt.dao.AdoptionRecordDAO;
import com.rimba.adopt.dao.FeedbackDAO;
import com.rimba.adopt.dao.PetsDAO;
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
            int shelterId = getShelterIdFromUserId(conn, userId); // Anda sudah ada method ini

            // ========== NEW: ADD DASHBOARD ACTION ==========
            // GANTI bahagian ini dalam doGet():
            if ("dashboard".equals(action)) {
                // Get all dashboard data
                DashboardData dashboardData = getDashboardData(conn, shelterId);

                // Set all attributes for JSP
                request.setAttribute("totalPets", dashboardData.getTotalPets());
                request.setAttribute("pendingRequests", dashboardData.getPendingRequests());
                request.setAttribute("approvedRequests", dashboardData.getApprovedRequests());
                request.setAttribute("rejectedRequests", dashboardData.getRejectedRequests());
                request.setAttribute("cancelledRequests", dashboardData.getCancelledRequests());
                request.setAttribute("averageRating", dashboardData.getAverageRating());
                request.setAttribute("monthlyStats", dashboardData.getMonthlyStats());
                request.setAttribute("monthlyFeedbackStats", dashboardData.getMonthlyFeedbackStats());

                // Forward to dashboard JSP
                request.getRequestDispatcher("dashboard_shelter.jsp").forward(request, response);
                return;
            } // TAMBAH ELSE untuk handle bila tiada action atau action lain
            else {
                // Default: redirect ke dashboard
                response.sendRedirect("ManageAdoptionRequest?action=dashboard");
                return;
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
