package com.rimba.adopt.controller;

import com.rimba.adopt.dao.FeedbackDAO;
import com.rimba.adopt.model.Feedback;
import com.rimba.adopt.util.DatabaseConnection;
import com.rimba.adopt.util.SessionUtil;
import javax.servlet.*;
import javax.servlet.http.*;
import javax.servlet.annotation.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Date;
import java.util.List;

@WebServlet("/FeedbackServlet")
@MultipartConfig
public class FeedbackServlet extends HttpServlet {

    private FeedbackDAO feedbackDAO;

    @Override
    public void init() throws ServletException {
        feedbackDAO = new FeedbackDAO();
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = request.getParameter("action");
        HttpSession session = request.getSession(false);

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        try {
            if ("getFeedback".equals(action)) {
                String shelterIdParam = request.getParameter("shelterId");
                String pageParam = request.getParameter("page");
                String pageSizeParam = request.getParameter("pageSize");

                if (shelterIdParam == null || shelterIdParam.isEmpty()) {
                    sendJsonResponse(out, false, "Shelter ID is required", null);
                    return;
                }

                int shelterId = Integer.parseInt(shelterIdParam);
                int page = pageParam != null ? Integer.parseInt(pageParam) : 1;
                int pageSize = pageSizeParam != null ? Integer.parseInt(pageSizeParam) : 4;

                // Get feedback data
                List<Feedback> feedbackList = feedbackDAO.getFeedbackByShelterId(shelterId, page, pageSize);
                int totalCount = feedbackDAO.getFeedbackCountByShelterId(shelterId);
                double averageRating = feedbackDAO.getAverageRatingByShelterId(shelterId);
                int[] ratingDistribution = feedbackDAO.getRatingDistributionByShelterId(shelterId);

                // Build JSON response manually
                StringBuilder json = new StringBuilder();
                json.append("{");
                json.append("\"success\": true,");
                json.append("\"totalCount\": ").append(totalCount).append(",");
                json.append("\"averageRating\": ").append(String.format("%.1f", averageRating)).append(",");
                json.append("\"currentPage\": ").append(page).append(",");
                json.append("\"pageSize\": ").append(pageSize).append(",");
                json.append("\"totalPages\": ").append((int) Math.ceil((double) totalCount / pageSize)).append(",");

                // Add feedback list
                json.append("\"feedbackList\": [");
                for (int i = 0; i < feedbackList.size(); i++) {
                    Feedback feedback = feedbackList.get(i);
                    if (i > 0) {
                        json.append(",");
                    }

                    String adopterName = feedbackDAO.getAdopterNameById(feedback.getAdopterId());
                    if (adopterName == null) {
                        adopterName = "Anonymous";
                    }

                    json.append("{");
                    json.append("\"feedbackId\": ").append(feedback.getFeedbackId()).append(",");
                    json.append("\"adopterId\": ").append(feedback.getAdopterId()).append(",");
                    json.append("\"shelterId\": ").append(feedback.getShelterId()).append(",");
                    json.append("\"rating\": ").append(feedback.getRating()).append(",");
                    json.append("\"comment\": \"").append(escapeJson(feedback.getComment())).append("\",");
                    json.append("\"adopterName\": \"").append(escapeJson(adopterName)).append("\",");
                    json.append("\"relativeTime\": \"").append(getRelativeTime(feedback.getCreatedAt())).append("\"");
                    json.append("}");
                }
                json.append("],");

                // Add rating distribution
                json.append("\"ratingDistribution\": [");
                for (int i = 0; i < ratingDistribution.length; i++) {
                    if (i > 0) {
                        json.append(",");
                    }
                    json.append(ratingDistribution[i]);
                }
                json.append("]");

                json.append("}");

                out.print(json.toString());

            } else if ("checkReview".equals(action)) {
                String shelterIdParam = request.getParameter("shelterId");

                if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isAdopter(session)) {
                    sendJsonResponse(out, false, "Unauthorized access", null);
                    return;
                }

                if (shelterIdParam == null || shelterIdParam.isEmpty()) {
                    sendJsonResponse(out, false, "Shelter ID is required", null);
                    return;
                }

                int shelterId = Integer.parseInt(shelterIdParam);
                int userId = SessionUtil.getUserId(session);

                boolean hasReviewed = feedbackDAO.hasAdopterReviewedShelter(userId, shelterId);

                out.print("{\"success\": true, \"hasReviewed\": " + hasReviewed + "}");

            } else {
                sendJsonResponse(out, false, "Invalid action", null);
            }

        } catch (NumberFormatException e) {
            sendJsonResponse(out, false, "Invalid parameter format", null);
        } catch (Exception e) {
            e.printStackTrace();
            sendJsonResponse(out, false, "Error: " + e.getMessage(), null);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isAdopter(session)) {
            sendJsonResponse(out, false, "Unauthorized access", null);
            return;
        }

        try {
            String shelterIdParam = request.getParameter("shelterId");
            String ratingParam = request.getParameter("rating");
            String title = request.getParameter("title");
            String comment = request.getParameter("comment");

            if (shelterIdParam == null || ratingParam == null || comment == null) {
                sendJsonResponse(out, false, "All fields are required", null);
                return;
            }

            int shelterId = Integer.parseInt(shelterIdParam);
            int rating = Integer.parseInt(ratingParam);
            int userId = SessionUtil.getUserId(session);

            // Validate rating
            if (rating < 1 || rating > 5) {
                sendJsonResponse(out, false, "Rating must be between 1 and 5", null);
                return;
            }

            // Check if user has already reviewed this shelter
            if (feedbackDAO.hasAdopterReviewedShelter(userId, shelterId)) {
                sendJsonResponse(out, false, "You have already reviewed this shelter", null);
                return;
            }

            // Combine title and comment if title exists
            String fullComment = comment;
            if (title != null && !title.trim().isEmpty()) {
                fullComment = title + " - " + comment;
            }

            // Create and save feedback
            Feedback feedback = new Feedback();
            feedback.setAdopterId(userId);
            feedback.setShelterId(shelterId);
            feedback.setRating(rating);
            feedback.setComment(fullComment.trim());
            feedback.setCreatedAt(new Timestamp(new Date().getTime()));

            boolean success = feedbackDAO.addFeedback(feedback);

            if (success) {
                sendJsonResponse(out, true, "Thank you for your review! Your feedback has been submitted.", null);
            } else {
                sendJsonResponse(out, false, "Failed to submit review. Please try again.", null);
            }

        } catch (NumberFormatException e) {
            sendJsonResponse(out, false, "Invalid rating format", null);
        } catch (Exception e) {
            e.printStackTrace();
            sendJsonResponse(out, false, "Error submitting review: " + e.getMessage(), null);
        }
    }

    // ========== BUANG/COMMENT METHOD INI ==========
    // Jangan letak public method deleteFeedback di sini
    // public boolean deleteFeedback(int feedbackId, int shelterId) { ... }
    // ==============================================
    @Override
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isShelter(session)) {
            sendJsonResponse(out, false, "Unauthorized access", null);
            return;
        }

        try {
            String feedbackIdParam = request.getParameter("feedbackId");
            int shelterId = SessionUtil.getUserId(session); // Shelter ID = user ID

            if (feedbackIdParam == null || feedbackIdParam.isEmpty()) {
                sendJsonResponse(out, false, "Feedback ID is required", null);
                return;
            }

            int feedbackId = Integer.parseInt(feedbackIdParam);

            // Delete feedback directly without calling helper method
            boolean success = performDeleteFeedback(feedbackId, shelterId);

            if (success) {
                sendJsonResponse(out, true, "Feedback deleted successfully", null);
            } else {
                sendJsonResponse(out, false, "Failed to delete feedback or feedback not found", null);
            }

        } catch (NumberFormatException e) {
            sendJsonResponse(out, false, "Invalid feedback ID", null);
        } catch (Exception e) {
            e.printStackTrace();
            sendJsonResponse(out, false, "Error: " + e.getMessage(), null);
        }
    }

    // ========== TAMBAH PRIVATE HELPER METHOD ==========
    private boolean performDeleteFeedback(int feedbackId, int shelterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            String sql = "DELETE FROM feedback WHERE feedback_id = ? AND shelter_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, feedbackId);
            pstmt.setInt(2, shelterId);

            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;

        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                }
            }
            DatabaseConnection.closeConnection(conn);
        }
    }

    private void sendJsonResponse(PrintWriter out, boolean success, String message, String data) {
        StringBuilder json = new StringBuilder();
        json.append("{");
        json.append("\"success\": ").append(success).append(",");
        json.append("\"message\": \"").append(escapeJson(message)).append("\"");

        if (data != null) {
            json.append(",\"data\": ").append(data);
        }

        json.append("}");
        out.print(json.toString());
    }

    private String escapeJson(String input) {
        if (input == null) {
            return "";
        }
        return input.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r")
                .replace("\t", "\\t");
    }

    private String getRelativeTime(Timestamp timestamp) {
        if (timestamp == null) {
            return "";
        }

        Date now = new Date();
        long diffInMillis = now.getTime() - timestamp.getTime();

        long diffInSeconds = diffInMillis / 1000;
        long diffInMinutes = diffInSeconds / 60;
        long diffInHours = diffInMinutes / 60;
        long diffInDays = diffInHours / 24;
        long diffInMonths = diffInDays / 30;
        long diffInYears = diffInDays / 365;

        if (diffInSeconds < 60) {
            return "just now";
        } else if (diffInMinutes < 60) {
            return diffInMinutes + " minute" + (diffInMinutes > 1 ? "s" : "") + " ago";
        } else if (diffInHours < 24) {
            return diffInHours + " hour" + (diffInHours > 1 ? "s" : "") + " ago";
        } else if (diffInDays < 30) {
            return diffInDays + " day" + (diffInDays > 1 ? "s" : "") + " ago";
        } else if (diffInMonths < 12) {
            return diffInMonths + " month" + (diffInMonths > 1 ? "s" : "") + " ago";
        } else {
            return diffInYears + " year" + (diffInYears > 1 ? "s" : "") + " ago";
        }
    }
}
