package com.rimba.adopt.dao;

import com.rimba.adopt.model.Feedback;
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class FeedbackDAO {

    // Add new feedback
    public boolean addFeedback(Feedback feedback) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "INSERT INTO feedback (adopter_id, shelter_id, rating, comment) VALUES (?, ?, ?, ?)";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, feedback.getAdopterId());
            pstmt.setInt(2, feedback.getShelterId());
            pstmt.setInt(3, feedback.getRating());
            pstmt.setString(4, feedback.getComment());
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
            
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
    }

    // Get feedback by shelter ID
    public List<Feedback> getFeedbackByShelterId(int shelterId, int page, int pageSize) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        List<Feedback> feedbackList = new ArrayList<Feedback>(); // Explicit type
        
        try {
            conn = DatabaseConnection.getConnection();
            int offset = (page - 1) * pageSize;
            
            String sql = "SELECT f.* FROM feedback f " +
                        "WHERE f.shelter_id = ? " +
                        "ORDER BY f.created_at DESC " +
                        "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            pstmt.setInt(2, offset);
            pstmt.setInt(3, pageSize);
            
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Feedback feedback = new Feedback();
                feedback.setFeedbackId(rs.getInt("feedback_id"));
                feedback.setAdopterId(rs.getInt("adopter_id"));
                feedback.setShelterId(rs.getInt("shelter_id"));
                feedback.setRating(rs.getInt("rating"));
                feedback.setComment(rs.getString("comment"));
                feedback.setCreatedAt(rs.getTimestamp("created_at"));
                
                feedbackList.add(feedback);
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
        
        return feedbackList;
    }

    // Get total feedback count for a shelter
    public int getFeedbackCountByShelterId(int shelterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        int count = 0;
        
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT COUNT(*) as total FROM feedback WHERE shelter_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            
            rs = pstmt.executeQuery();
            if (rs.next()) {
                count = rs.getInt("total");
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
        
        return count;
    }

    // Get average rating for a shelter
    public double getAverageRatingByShelterId(int shelterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        double average = 0.0;
        
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT AVG(CAST(rating AS DOUBLE)) as average FROM feedback WHERE shelter_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            
            rs = pstmt.executeQuery();
            if (rs.next()) {
                average = rs.getDouble("average");
                if (rs.wasNull()) {
                    average = 0.0;
                }
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
        
        return average;
    }

    // Get rating distribution for a shelter
    public int[] getRatingDistributionByShelterId(int shelterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        int[] distribution = new int[5];
        
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT rating, COUNT(*) as count " +
                        "FROM feedback WHERE shelter_id = ? " +
                        "GROUP BY rating ORDER BY rating";
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            
            rs = pstmt.executeQuery();
            
            // Initialize all to 0
            for (int i = 0; i < 5; i++) {
                distribution[i] = 0;
            }
            
            while (rs.next()) {
                int rating = rs.getInt("rating");
                int count = rs.getInt("count");
                if (rating >= 1 && rating <= 5) {
                    distribution[rating - 1] = count;
                }
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
        
        return distribution;
    }

    // Check if adopter has already reviewed this shelter
    public boolean hasAdopterReviewedShelter(int adopterId, int shelterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT COUNT(*) as count FROM feedback WHERE adopter_id = ? AND shelter_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, adopterId);
            pstmt.setInt(2, shelterId);
            
            rs = pstmt.executeQuery();
            if (rs.next()) {
                return rs.getInt("count") > 0;
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
        
        return false;
    }
    
    // ========== METHODS FOR DASHBOARD SHELTER ==========

// Get monthly feedback statistics - NEW METHOD
public Map<String, Object> getMonthlyFeedbackStats(int shelterId) {
    Map<String, Object> stats = new HashMap<>();
    
    // Check database type and adjust SQL accordingly
    String query = "";
    
    // Try PostgreSQL syntax first (TO_CHAR)
    query = "SELECT "
            + "    TO_CHAR(f.created_at, 'Mon') as month_short, "
            + "    EXTRACT(MONTH FROM f.created_at) as month_num, "
            + "    AVG(CAST(f.rating AS DOUBLE PRECISION)) as avg_rating "
            + "FROM feedback f "
            + "WHERE f.shelter_id = ? "
            + "    AND EXTRACT(YEAR FROM f.created_at) = EXTRACT(YEAR FROM CURRENT_DATE) "
            + "GROUP BY TO_CHAR(f.created_at, 'Mon'), "
            + "         EXTRACT(MONTH FROM f.created_at) "
            + "ORDER BY month_num";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DatabaseConnection.getConnection();
        pstmt = conn.prepareStatement(query);
        pstmt.setInt(1, shelterId);
        
        rs = pstmt.executeQuery();
        
        // Initialize arrays
        List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                                           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
        double[] monthlyRatings = new double[12];
        
        // Initialize all ratings to 0
        for (int i = 0; i < 12; i++) {
            monthlyRatings[i] = 0.0;
        }
        
        while (rs.next()) {
            String monthShort = rs.getString("month_short");
            int monthNum = rs.getInt("month_num") - 1; // Convert to 0-indexed
            double avgRating = rs.getDouble("avg_rating");
            
            if (monthNum >= 0 && monthNum < 12) {
                monthlyRatings[monthNum] = avgRating;
            }
        }
        
        stats.put("months", months);
        stats.put("monthlyRatings", monthlyRatings);
        
    } catch (SQLException e) {
        // Try MySQL syntax if PostgreSQL fails
        try {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            
            query = "SELECT "
                    + "    DATE_FORMAT(f.created_at, '%b') as month_short, "
                    + "    MONTH(f.created_at) as month_num, "
                    + "    AVG(f.rating) as avg_rating "
                    + "FROM feedback f "
                    + "WHERE f.shelter_id = ? "
                    + "    AND YEAR(f.created_at) = YEAR(CURRENT_DATE()) "
                    + "GROUP BY DATE_FORMAT(f.created_at, '%b'), "
                    + "         MONTH(f.created_at) "
                    + "ORDER BY month_num";
            
            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, shelterId);
            
            rs = pstmt.executeQuery();
            
            // Re-initialize
            List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun", 
                                               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
            double[] monthlyRatings = new double[12];
            
            for (int i = 0; i < 12; i++) {
                monthlyRatings[i] = 0.0;
            }
            
            while (rs.next()) {
                String monthShort = rs.getString("month_short");
                int monthNum = rs.getInt("month_num") - 1;
                double avgRating = rs.getDouble("avg_rating");
                
                if (monthNum >= 0 && monthNum < 12) {
                    monthlyRatings[monthNum] = avgRating;
                }
            }
            
            stats.put("months", months);
            stats.put("monthlyRatings", monthlyRatings);
            
        } catch (SQLException e2) {
            e2.printStackTrace();
        }
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
        DatabaseConnection.closeConnection(conn);
    }
    
    return stats;
}

// Get recent feedback with adopter names - NEW METHOD (optional)
public List<Map<String, Object>> getRecentFeedbackWithNames(int shelterId, int limit) {
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    List<Map<String, Object>> feedbackList = new ArrayList<>();
    
    try {
        conn = DatabaseConnection.getConnection();
        
        // Try PostgreSQL LIMIT syntax
        String sql = "SELECT f.*, u.name as adopter_name, u.profile_photo_path as adopter_photo " +
                    "FROM feedback f " +
                    "JOIN users u ON f.adopter_id = u.user_id " +
                    "WHERE f.shelter_id = ? " +
                    "ORDER BY f.created_at DESC " +
                    "LIMIT ?";
        
        pstmt = conn.prepareStatement(sql);
        pstmt.setInt(1, shelterId);
        pstmt.setInt(2, limit);
        
        rs = pstmt.executeQuery();
        
        while (rs.next()) {
            Map<String, Object> feedback = new HashMap<>();
            feedback.put("feedback_id", rs.getInt("feedback_id"));
            feedback.put("adopter_id", rs.getInt("adopter_id"));
            feedback.put("shelter_id", rs.getInt("shelter_id"));
            feedback.put("rating", rs.getInt("rating"));
            feedback.put("comment", rs.getString("comment"));
            feedback.put("created_at", rs.getTimestamp("created_at"));
            feedback.put("adopter_name", rs.getString("adopter_name"));
            feedback.put("adopter_photo", rs.getString("adopter_photo"));
            
            feedbackList.add(feedback);
        }
        
    } catch (SQLException e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
        DatabaseConnection.closeConnection(conn);
    }
    
    return feedbackList;
}
    
    

    // Get adopter name by ID
    public String getAdopterNameById(int adopterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        String name = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT name FROM users WHERE user_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, adopterId);
            
            rs = pstmt.executeQuery();
            if (rs.next()) {
                name = rs.getString("name");
            }
            
        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
        
        return name;
    }

}