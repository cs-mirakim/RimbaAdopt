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
import java.util.Map;

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

                // Get feedback data with adopter info
                List<Map<String, Object>> feedbackList = feedbackDAO.getFeedbackWithAdopterInfo(shelterId, page, pageSize);
                int totalCount = feedbackDAO.getFeedbackCountByShelterId(shelterId);
                double averageRating = feedbackDAO.getAverageRatingByShelterId(shelterId);
                int[] ratingDistribution = feedbackDAO.getRatingDistributionByShelterId(shelterId);

                System.out.println("DEBUG: Feedback stats - total: " + totalCount
                        + ", avg: " + averageRating
                        + ", current page: " + page);

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
                    Map<String, Object> feedback = feedbackList.get(i);
                    if (i > 0) {
                        json.append(",");
                    }

                    String adopterName = (String) feedback.get("adopter_name");
                    if (adopterName == null || adopterName.isEmpty()) {
                        adopterName = "Anonymous";
                    }

                    // Get comment safely
                    String comment = (String) feedback.get("comment");
                    if (comment == null) {
                        comment = "";
                    }

                    // Get relative time
                    Timestamp createdAt = (Timestamp) feedback.get("created_at");
                    String relativeTime = getRelativeTime(createdAt);

                    json.append("{");
                    json.append("\"feedbackId\": ").append(feedback.get("feedback_id")).append(",");
                    json.append("\"adopterId\": ").append(feedback.get("adopter_id")).append(",");
                    json.append("\"shelterId\": ").append(feedback.get("shelter_id")).append(",");
                    json.append("\"rating\": ").append(feedback.get("rating")).append(",");
                    json.append("\"comment\": \"").append(escapeJson(comment)).append("\",");
                    json.append("\"adopterName\": \"").append(escapeJson(adopterName)).append("\",");
                    json.append("\"createdAt\": \"").append(createdAt != null ? createdAt.toString() : "").append("\",");
                    json.append("\"relativeTime\": \"").append(escapeJson(relativeTime)).append("\"");
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

        System.out.println("DEBUG: doPost called - checking authentication");

        if (!SessionUtil.isLoggedIn(session)) {
            System.out.println("DEBUG: User not logged in");
            sendJsonResponse(out, false, "Unauthorized access. Please login.", null);
            return;
        }

        if (!SessionUtil.isAdopter(session)) {
            System.out.println("DEBUG: User not adopter");
            sendJsonResponse(out, false, "Unauthorized access. Please login as adopter.", null);
            return;
        }

        try {
            String action = request.getParameter("action");
            System.out.println("DEBUG: Action = " + action);

            if ("submitFeedback".equals(action)) {
                System.out.println("DEBUG: Processing submitFeedback...");
                String shelterIdParam = request.getParameter("shelterId");
                String ratingParam = request.getParameter("rating");
                String comment = request.getParameter("comment");
                String forceSubmit = request.getParameter("forceSubmit");

                System.out.println("DEBUG: Submitting feedback - shelterId: " + shelterIdParam
                        + ", rating: " + ratingParam
                        + ", comment length: " + (comment != null ? comment.length() : 0)
                        + ", forceSubmit: " + forceSubmit);

                if (shelterIdParam == null || shelterIdParam.isEmpty()) {
                    sendJsonResponse(out, false, "Shelter ID is required", null);
                    return;
                }

                if (ratingParam == null || ratingParam.isEmpty()) {
                    sendJsonResponse(out, false, "Rating is required", null);
                    return;
                }

                if (comment == null || comment.trim().isEmpty()) {
                    sendJsonResponse(out, false, "Comment cannot be empty", null);
                    return;
                }

                int shelterId = Integer.parseInt(shelterIdParam);
                int rating = Integer.parseInt(ratingParam);
                int adopterId = SessionUtil.getUserId(session);

                // Validate rating
                if (rating < 1 || rating > 5) {
                    sendJsonResponse(out, false, "Rating must be between 1 and 5", null);
                    return;
                }

                // Skip duplicate check jika forceSubmit=true
                boolean hasReviewed = false;
                if (!"true".equalsIgnoreCase(forceSubmit)) {
                    hasReviewed = feedbackDAO.hasAdopterReviewedShelter(adopterId, shelterId);
                    if (hasReviewed) {
                        sendJsonResponse(out, false, "You have already reviewed this shelter", null);
                        return;
                    }
                }

                // Create feedback object
                Feedback feedback = new Feedback();
                feedback.setAdopterId(adopterId);
                feedback.setShelterId(shelterId);
                feedback.setRating(rating);
                feedback.setComment(comment.trim());

                // Add feedback
                boolean success = feedbackDAO.addFeedback(feedback);

                if (success) {
                    System.out.println("DEBUG: Feedback submitted successfully for shelter " + shelterId);
                    sendJsonResponse(out, true, "Thank you for your feedback!", null);
                } else {
                    sendJsonResponse(out, false, "Failed to submit feedback. Please try again.", null);
                }

            } else if ("updateFeedback".equals(action)) {
                System.out.println("DEBUG: Processing updateFeedback...");

                String feedbackIdParam = request.getParameter("feedbackId");
                String ratingParam = request.getParameter("rating");
                String comment = request.getParameter("comment");

                System.out.println("DEBUG: feedbackId=" + feedbackIdParam
                        + ", rating=" + ratingParam
                        + ", comment=" + (comment != null ? comment.substring(0, Math.min(50, comment.length())) + "..." : "null"));

                if (feedbackIdParam == null || feedbackIdParam.isEmpty()) {
                    sendJsonResponse(out, false, "Feedback ID is required", null);
                    return;
                }

                if (ratingParam == null || ratingParam.isEmpty()) {
                    sendJsonResponse(out, false, "Rating is required", null);
                    return;
                }

                if (comment == null || comment.trim().isEmpty()) {
                    sendJsonResponse(out, false, "Comment cannot be empty", null);
                    return;
                }

                try {
                    int feedbackId = Integer.parseInt(feedbackIdParam);
                    int rating = Integer.parseInt(ratingParam);
                    int adopterId = SessionUtil.getUserId(session);

                    // Validate rating
                    if (rating < 1 || rating > 5) {
                        sendJsonResponse(out, false, "Rating must be between 1 and 5", null);
                        return;
                    }

                    // Check if feedback belongs to this adopter
                    Map<String, Object> feedbackDetails = feedbackDAO.getFeedbackDetailsForAdopter(feedbackId, adopterId);
                    if (feedbackDetails.isEmpty()) {
                        sendJsonResponse(out, false, "Feedback not found or you don't have permission to edit it", null);
                        return;
                    }

                    // Update feedback
                    boolean success = feedbackDAO.updateFeedback(feedbackId, rating, comment.trim());

                    if (success) {
                        System.out.println("DEBUG: Feedback updated successfully");
                        sendJsonResponse(out, true, "✓ Feedback updated successfully!", null);
                    } else {
                        sendJsonResponse(out, false, "Failed to update feedback", null);
                    }

                } catch (NumberFormatException e) {
                    System.err.println("ERROR: Invalid number format in updateFeedback: " + e.getMessage());
                    sendJsonResponse(out, false, "Invalid parameter format", null);
                } catch (Exception e) {
                    e.printStackTrace();
                    sendJsonResponse(out, false, "Error: " + e.getMessage(), null);
                }

            } else {
                sendJsonResponse(out, false, "Invalid action", null);
            }

        } catch (NumberFormatException e) {
            System.err.println("ERROR: Invalid number format: " + e.getMessage());
            sendJsonResponse(out, false, "Invalid data format. Please check your input.", null);
        } catch (Exception e) {
            e.printStackTrace();
            sendJsonResponse(out, false, "Error: " + e.getMessage(), null);
        }
    }

    @Override
    protected void doPut(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("DEBUG: doPut called");

        HttpSession session = request.getSession(false);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        if (!SessionUtil.isLoggedIn(session) || !SessionUtil.isAdopter(session)) {
            sendJsonResponse(out, false, "Unauthorized access", null);
            return;
        }

        try {
            String action = request.getParameter("action");

            if ("updateFeedback".equals(action)) {
                System.out.println("DEBUG: Updating feedback via PUT...");

                String feedbackIdParam = request.getParameter("feedbackId");
                String ratingParam = request.getParameter("rating");
                String comment = request.getParameter("comment");

                System.out.println("DEBUG: feedbackId=" + feedbackIdParam
                        + ", rating=" + ratingParam
                        + ", comment=" + (comment != null ? comment.substring(0, Math.min(50, comment.length())) + "..." : "null"));

                if (feedbackIdParam == null || ratingParam == null || comment == null) {
                    sendJsonResponse(out, false, "All fields are required", null);
                    return;
                }

                try {
                    int feedbackId = Integer.parseInt(feedbackIdParam);
                    int rating = Integer.parseInt(ratingParam);
                    int adopterId = SessionUtil.getUserId(session);

                    // Validate rating
                    if (rating < 1 || rating > 5) {
                        sendJsonResponse(out, false, "Rating must be between 1 and 5", null);
                        return;
                    }

                    // Validate comment
                    if (comment.trim().isEmpty()) {
                        sendJsonResponse(out, false, "Comment cannot be empty", null);
                        return;
                    }

                    // Check if feedback belongs to this adopter
                    Map<String, Object> feedbackDetails = feedbackDAO.getFeedbackDetailsForAdopter(feedbackId, adopterId);
                    if (feedbackDetails.isEmpty()) {
                        sendJsonResponse(out, false, "Feedback not found or you don't have permission to edit it", null);
                        return;
                    }

                    // Update feedback
                    boolean success = feedbackDAO.updateFeedback(feedbackId, rating, comment);

                    if (success) {
                        sendJsonResponse(out, true, "✓ Feedback updated successfully!", null);
                    } else {
                        sendJsonResponse(out, false, "✗ Failed to update feedback", null);
                    }

                } catch (NumberFormatException e) {
                    sendJsonResponse(out, false, "Invalid parameter format", null);
                } catch (Exception e) {
                    e.printStackTrace();
                    sendJsonResponse(out, false, "Error: " + e.getMessage(), null);
                }
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
    protected void doDelete(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        System.out.println("DEBUG: doDelete called");

        HttpSession session = request.getSession(false);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        if (!SessionUtil.isLoggedIn(session)) {
            sendJsonResponse(out, false, "Unauthorized access", null);
            return;
        }

        try {
            String feedbackIdParam = request.getParameter("feedbackId");

            if (feedbackIdParam == null || feedbackIdParam.isEmpty()) {
                sendJsonResponse(out, false, "Feedback ID is required", null);
                return;
            }

            int feedbackId = Integer.parseInt(feedbackIdParam);
            int userId = SessionUtil.getUserId(session);
            boolean success = false;

            if (SessionUtil.isAdopter(session)) {
                System.out.println("DEBUG: Adopter deleting feedback ID: " + feedbackId);
                success = feedbackDAO.deleteFeedbackByAdopter(feedbackId, userId);
            } else if (SessionUtil.isShelter(session)) {
                System.out.println("DEBUG: Shelter deleting feedback ID: " + feedbackId);
                success = performDeleteFeedback(feedbackId, userId);
            } else {
                sendJsonResponse(out, false, "Unauthorized access", null);
                return;
            }

            if (success) {
                System.out.println("DEBUG: Feedback deleted successfully");
                sendJsonResponse(out, true, "Feedback deleted successfully", null);
            } else {
                System.out.println("DEBUG: Failed to delete feedback");
                sendJsonResponse(out, false, "Failed to delete feedback or feedback not found", null);
            }

        } catch (NumberFormatException e) {
            sendJsonResponse(out, false, "Invalid feedback ID", null);
        } catch (Exception e) {
            e.printStackTrace();
            sendJsonResponse(out, false, "Error: " + e.getMessage(), null);
        }
    }

    // ========== PRIVATE HELPER METHODS ==========
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
