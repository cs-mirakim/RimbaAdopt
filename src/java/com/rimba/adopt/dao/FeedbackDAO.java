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

    // FeedbackDAO.java - BETULKAN method addFeedback()
    public boolean addFeedback(Feedback feedback) {
        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            String sql = "INSERT INTO feedback (adopter_id, shelter_id, rating, comment, created_at) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, feedback.getAdopterId());
            pstmt.setInt(2, feedback.getShelterId());
            pstmt.setInt(3, feedback.getRating());

            if (feedback.getComment() != null) {
                pstmt.setString(4, feedback.getComment());
            } else {
                pstmt.setNull(4, Types.CLOB);
            }

            int rowsAffected = pstmt.executeUpdate();
            System.out.println("DEBUG: Added feedback for shelter " + feedback.getShelterId()
                    + " by adopter " + feedback.getAdopterId()
                    + ", Rows affected: " + rowsAffected);
            return rowsAffected > 0;

        } catch (SQLException e) {
            System.err.println("ERROR in addFeedback: " + e.getMessage());
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

    // Dalam FeedbackDAO.java - Update getFeedbackByShelterId method:
    // Dalam FeedbackDAO.java - Update getFeedbackByShelterId method:
    public List<Feedback> getFeedbackByShelterId(int shelterId, int page, int pageSize) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        List<Feedback> feedbackList = new ArrayList<>();

        try {
            conn = DatabaseConnection.getConnection();

            // Calculate offset for pagination
            int offset = (page - 1) * pageSize;

            // Use Derby syntax for pagination
            String sql = "SELECT f.* FROM feedback f "
                    + "WHERE f.shelter_id = ? "
                    + "ORDER BY f.created_at DESC "
                    + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

            System.out.println("DEBUG: Getting feedback for shelter " + shelterId
                    + ", page " + page + ", pageSize " + pageSize);

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

            System.out.println("DEBUG: Found " + feedbackList.size() + " feedback records");

        } catch (SQLException e) {
            System.err.println("ERROR in getFeedbackByShelterId: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                }
            }
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
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                }
            }
            DatabaseConnection.closeConnection(conn);
        }

        return count;
    }

    public double getAverageRatingByShelterId(int shelterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        double average = 0.0;

        try {
            conn = DatabaseConnection.getConnection();
            // GUNA AVG() sahaja tanpa CAST
            String sql = "SELECT AVG(rating) as average FROM feedback WHERE shelter_id = ?";
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
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                }
            }
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
            String sql = "SELECT rating, COUNT(*) as count "
                    + "FROM feedback WHERE shelter_id = ? "
                    + "GROUP BY rating ORDER BY rating";

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
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                }
            }
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
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                }
            }
            DatabaseConnection.closeConnection(conn);
        }

        return false;
    }

    // ========== METHODS FOR DASHBOARD SHELTER ==========
// Get monthly feedback statistics - NEW METHOD
// ========== FIX THIS METHOD IN FeedbackDAO.java ==========
// Get monthly feedback statistics
    public Map<String, Object> getMonthlyFeedbackStats(int shelterId) {
        Map<String, Object> result = new HashMap<>();
        String sql = "SELECT MONTH(created_at) as month, AVG(rating) as avg_rating "
                + "FROM feedback "
                + "WHERE shelter_id = ? AND YEAR(created_at) = YEAR(CURRENT_DATE) "
                + "GROUP BY MONTH(created_at) "
                + "ORDER BY MONTH(created_at)";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            rs = pstmt.executeQuery();

            // Initialize array with zeros
            double[] monthlyRatings = new double[12];
            Arrays.fill(monthlyRatings, 0.0);

            while (rs.next()) {
                int month = rs.getInt("month") - 1; // Convert to 0-based index
                double avgRating = rs.getDouble("avg_rating");

                // Debug log
                System.out.println("DEBUG Feedback - Month: " + month + ", Avg Rating: " + avgRating);

                if (!rs.wasNull()) {
                    monthlyRatings[month] = avgRating;
                }
            }

            // Debug log array
            System.out.println("DEBUG Feedback - Ratings array: " + Arrays.toString(monthlyRatings));

            result.put("monthlyRatings", monthlyRatings);
            return result;

        } catch (SQLException e) {
            System.err.println("Error getting monthly feedback stats: " + e.getMessage());
            e.printStackTrace();
            return null;
        } finally {
            try {
                if (rs != null) {
                    rs.close();
                }
                if (pstmt != null) {
                    pstmt.close();
                }
                if (conn != null) {
                    conn.close();
                }
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
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
            String sql = "SELECT f.*, u.name as adopter_name, u.profile_photo_path as adopter_photo "
                    + "FROM feedback f "
                    + "JOIN users u ON f.adopter_id = u.user_id "
                    + "WHERE f.shelter_id = ? "
                    + "ORDER BY f.created_at DESC "
                    + "LIMIT ?";

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
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                }
            }
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
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                }
            }
            DatabaseConnection.closeConnection(conn);
        }

        return name;
    }

    // Get feedback by adopter ID with shelter details
    public List<Object[]> getFeedbackByAdopterId(int adopterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        List<Object[]> feedbackList = new ArrayList<>();

        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT f.feedback_id, s.shelter_name, f.rating, f.comment, f.created_at, "
                    + "u.profile_photo_path "
                    + "FROM feedback f "
                    + "JOIN shelter s ON f.shelter_id = s.shelter_id "
                    + "JOIN users u ON s.shelter_id = u.user_id "
                    + "WHERE f.adopter_id = ? "
                    + "ORDER BY f.created_at DESC";

            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, adopterId);

            rs = pstmt.executeQuery();

            while (rs.next()) {
                Object[] feedback = new Object[6];
                feedback[0] = rs.getInt("feedback_id");
                feedback[1] = rs.getString("shelter_name");
                feedback[2] = rs.getInt("rating");
                feedback[3] = rs.getString("comment");
                feedback[4] = rs.getTimestamp("created_at");
                feedback[5] = rs.getString("profile_photo_path");

                feedbackList.add(feedback);
            }

        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                }
            }
            DatabaseConnection.closeConnection(conn);
        }

        return feedbackList;
    }

    // Update feedback by adopter
    public boolean updateFeedback(int feedbackId, int rating, String comment) {
        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            String sql = "UPDATE feedback SET rating = ?, comment = ?, created_at = CURRENT_TIMESTAMP "
                    + "WHERE feedback_id = ?";

            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, rating);
            pstmt.setString(2, comment);
            pstmt.setInt(3, feedbackId);

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

    // Delete feedback by adopter
    public boolean deleteFeedbackByAdopter(int feedbackId, int adopterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            String sql = "DELETE FROM feedback WHERE feedback_id = ? AND adopter_id = ?";

            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, feedbackId);
            pstmt.setInt(2, adopterId);

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

    // Get feedback details by ID for adopter
    public Map<String, Object> getFeedbackDetailsForAdopter(int feedbackId, int adopterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        Map<String, Object> feedbackDetails = new HashMap<>();

        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT f.*, s.shelter_name, u.profile_photo_path "
                    + "FROM feedback f "
                    + "JOIN shelter s ON f.shelter_id = s.shelter_id "
                    + "JOIN users u ON s.shelter_id = u.user_id "
                    + "WHERE f.feedback_id = ? AND f.adopter_id = ?";

            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, feedbackId);
            pstmt.setInt(2, adopterId);

            rs = pstmt.executeQuery();

            if (rs.next()) {
                feedbackDetails.put("feedbackId", rs.getInt("feedback_id"));
                feedbackDetails.put("shelterId", rs.getInt("shelter_id"));
                feedbackDetails.put("rating", rs.getInt("rating"));
                feedbackDetails.put("comment", rs.getString("comment"));
                feedbackDetails.put("createdAt", rs.getTimestamp("created_at"));
                feedbackDetails.put("shelterName", rs.getString("shelter_name"));
                feedbackDetails.put("shelterPhoto", rs.getString("profile_photo_path"));
            }

        } catch (SQLException e) {
            e.printStackTrace();
        } finally {
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                }
            }
            DatabaseConnection.closeConnection(conn);
        }

        return feedbackDetails;
    }

    // FeedbackDAO.java - TAMBAH method ini
    public List<Map<String, Object>> getFeedbackWithAdopterInfo(int shelterId, int page, int pageSize) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        List<Map<String, Object>> feedbackList = new ArrayList<>();

        try {
            conn = DatabaseConnection.getConnection();

            // Calculate offset for pagination
            int offset = (page - 1) * pageSize;

            // Use Derby syntax for pagination
            String sql = "SELECT f.*, u.name as adopter_name FROM feedback f "
                    + "JOIN users u ON f.adopter_id = u.user_id "
                    + "WHERE f.shelter_id = ? "
                    + "ORDER BY f.created_at DESC "
                    + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";

            System.out.println("DEBUG: Getting feedback for shelter " + shelterId
                    + ", page " + page + ", pageSize " + pageSize);

            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            pstmt.setInt(2, offset);
            pstmt.setInt(3, pageSize);

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

                feedbackList.add(feedback);
            }

            System.out.println("DEBUG: Found " + feedbackList.size() + " feedback records");

        } catch (SQLException e) {
            System.err.println("ERROR in getFeedbackWithAdopterInfo: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                }
            }
            DatabaseConnection.closeConnection(conn);
        }

        return feedbackList;
    }
}
