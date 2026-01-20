package com.rimba.adopt.dao;

import com.rimba.adopt.model.Shelter;
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class ShelterDAO {

    // Get all approved shelters
    public List<Shelter> getAllApprovedShelters() {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        List<Shelter> shelters = new ArrayList<>();
        
        try {
            conn = DatabaseConnection.getConnection();
            
            String sql = "SELECT s.*, u.email, u.phone, u.profile_photo_path " +
                        "FROM shelter s " +
                        "JOIN users u ON s.shelter_id = u.user_id " +
                        "WHERE s.approval_status = 'approved' " +
                        "ORDER BY s.shelter_name";
            
            pstmt = conn.prepareStatement(sql);
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Shelter shelter = new Shelter();
                
                shelter.setShelterId(rs.getInt("shelter_id"));
                shelter.setShelterName(rs.getString("shelter_name"));
                shelter.setShelterAddress(rs.getString("shelter_address"));
                shelter.setShelterDescription(rs.getString("shelter_description"));
                shelter.setWebsite(rs.getString("website"));
                shelter.setOperatingHours(rs.getString("operating_hours"));
                shelter.setApprovalStatus(rs.getString("approval_status"));
                
                int reviewedBy = rs.getInt("reviewed_by");
                if (!rs.wasNull()) {
                    shelter.setReviewedBy(reviewedBy);
                }
                
                shelter.setEmail(rs.getString("email"));
                shelter.setPhone(rs.getString("phone"));
                
                String profilePhoto = rs.getString("profile_photo_path");
                if (profilePhoto != null && !profilePhoto.isEmpty()) {
                    shelter.setPhotoPath(profilePhoto);
                } else {
                    shelter.setPhotoPath("profile_picture/shelter/default.png");
                }
                
                // Initialize rating to 0
                shelter.setAvgRating(0.0);
                shelter.setReviewCount(0);
                
                shelters.add(shelter);
            }
            
        } catch (SQLException e) {
            System.err.println("Error in ShelterDAO.getAllApprovedShelters(): " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
        
        return shelters;
    }

    // Get shelter by ID
    public Shelter getShelterById(int shelterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT s.*, u.email, u.phone, u.profile_photo_path " +
                        "FROM shelter s " +
                        "JOIN users u ON s.shelter_id = u.user_id " +
                        "WHERE s.shelter_id = ?";
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                Shelter shelter = new Shelter();
                
                shelter.setShelterId(rs.getInt("shelter_id"));
                shelter.setShelterName(rs.getString("shelter_name"));
                shelter.setShelterAddress(rs.getString("shelter_address"));
                shelter.setShelterDescription(rs.getString("shelter_description"));
                shelter.setWebsite(rs.getString("website"));
                shelter.setOperatingHours(rs.getString("operating_hours"));
                shelter.setApprovalStatus(rs.getString("approval_status"));
                
                int reviewedBy = rs.getInt("reviewed_by");
                if (!rs.wasNull()) {
                    shelter.setReviewedBy(reviewedBy);
                }
                
                Timestamp reviewedAt = rs.getTimestamp("reviewed_at");
                if (!rs.wasNull()) {
                    shelter.setReviewedAt(reviewedAt);
                }
                
                shelter.setApprovalMessage(rs.getString("approval_message"));
                shelter.setRejectionReason(rs.getString("rejection_reason"));
                
                int notificationSent = rs.getInt("notification_sent");
                if (!rs.wasNull()) {
                    shelter.setNotificationSent(notificationSent);
                }
                
                Timestamp notificationSentAt = rs.getTimestamp("notification_sent_at");
                if (!rs.wasNull()) {
                    shelter.setNotificationSentAt(notificationSentAt);
                }
                
                shelter.setEmail(rs.getString("email"));
                shelter.setPhone(rs.getString("phone"));
                
                String profilePhoto = rs.getString("profile_photo_path");
                if (profilePhoto != null && !profilePhoto.isEmpty()) {
                    shelter.setPhotoPath(profilePhoto);
                } else {
                    shelter.setPhotoPath("profile_picture/shelter/default.png");
                }
                
                // Get rating separately
                FeedbackDAO feedbackDAO = new FeedbackDAO();
                shelter.setAvgRating(feedbackDAO.getAverageRatingByShelterId(shelterId));
                shelter.setReviewCount(feedbackDAO.getFeedbackCountByShelterId(shelterId));
                
                return shelter;
            }
            
        } catch (SQLException e) {
            System.err.println("Error in ShelterDAO.getShelterById(): " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
        
        return null;
    }

    // Get shelters with rating - FIXED VERSION
    public List<Shelter> getSheltersForPublic() {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        List<Shelter> shelters = new ArrayList<>();
        
        try {
            conn = DatabaseConnection.getConnection();
            
            System.out.println("=== DEBUG: Loading shelters with ratings ===");
            
            // ALTERNATE QUERY - lebih reliable
            String sql = "SELECT " +
                        "s.shelter_id, " +
                        "s.shelter_name, " +
                        "s.shelter_address, " +
                        "s.shelter_description, " +
                        "s.website, " +
                        "s.operating_hours, " +
                        "s.approval_status, " +
                        "u.email, " +
                        "u.phone, " +
                        "u.profile_photo_path, " +
                        "(SELECT COALESCE(AVG(rating), 0.0) FROM feedback WHERE shelter_id = s.shelter_id) as avg_rating, " +
                        "(SELECT COUNT(feedback_id) FROM feedback WHERE shelter_id = s.shelter_id) as review_count " +
                        "FROM shelter s " +
                        "JOIN users u ON s.shelter_id = u.user_id " +
                        "WHERE s.approval_status = 'approved' " +
                        "ORDER BY s.shelter_name";
            
            pstmt = conn.prepareStatement(sql);
            rs = pstmt.executeQuery();
            
            int count = 0;
            while (rs.next()) {
                count++;
                Shelter shelter = new Shelter();
                
                shelter.setShelterId(rs.getInt("shelter_id"));
                shelter.setShelterName(rs.getString("shelter_name"));
                shelter.setShelterAddress(rs.getString("shelter_address"));
                shelter.setShelterDescription(rs.getString("shelter_description"));
                shelter.setWebsite(rs.getString("website"));
                shelter.setOperatingHours(rs.getString("operating_hours"));
                shelter.setApprovalStatus(rs.getString("approval_status"));
                shelter.setEmail(rs.getString("email"));
                shelter.setPhone(rs.getString("phone"));
                
                double avgRating = rs.getDouble("avg_rating");
                int reviewCount = rs.getInt("review_count");
                
                shelter.setAvgRating(avgRating);
                shelter.setReviewCount(reviewCount);
                
                System.out.println("Shelter #" + count + ": " + shelter.getShelterName() + 
                                 " - Rating: " + avgRating + " - Reviews: " + reviewCount);
                
                String profilePhoto = rs.getString("profile_photo_path");
                if (profilePhoto != null && !profilePhoto.isEmpty()) {
                    shelter.setPhotoPath(profilePhoto);
                } else {
                    shelter.setPhotoPath("profile_picture/shelter/default.png");
                }
                
                shelters.add(shelter);
            }
            
            System.out.println("=== DEBUG: Total shelters loaded: " + shelters.size() + " ===");
            
            // Jika masih 0 rating, tambah test data
            if (shelters.size() > 0 && shelters.get(0).getAvgRating() == 0.0) {
                System.out.println("WARNING: All shelters have 0.0 rating. Check if feedback table has data.");
            }
            
        } catch (SQLException e) {
            System.err.println("ERROR in ShelterDAO.getSheltersForPublic(): " + e.getMessage());
            e.printStackTrace();
            return getAllApprovedShelters();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
        
        return shelters;
    }
    
    // Get shelter with rating statistics
    public Shelter getShelterWithRating(int shelterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            String sql = "SELECT s.*, u.email, u.phone, u.profile_photo_path, " +
                        "(SELECT COALESCE(AVG(rating), 0.0) FROM feedback WHERE shelter_id = s.shelter_id) as avg_rating, " +
                        "(SELECT COUNT(feedback_id) FROM feedback WHERE shelter_id = s.shelter_id) as review_count " +
                        "FROM shelter s " +
                        "JOIN users u ON s.shelter_id = u.user_id " +
                        "WHERE s.shelter_id = ?";

            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            rs = pstmt.executeQuery();

            if (rs.next()) {
                Shelter shelter = new Shelter();

                shelter.setShelterId(rs.getInt("shelter_id"));
                shelter.setShelterName(rs.getString("shelter_name"));
                shelter.setShelterAddress(rs.getString("shelter_address"));
                shelter.setShelterDescription(rs.getString("shelter_description"));
                shelter.setWebsite(rs.getString("website"));
                shelter.setOperatingHours(rs.getString("operating_hours"));
                shelter.setApprovalStatus(rs.getString("approval_status"));

                int reviewedBy = rs.getInt("reviewed_by");
                if (!rs.wasNull()) {
                    shelter.setReviewedBy(reviewedBy);
                }

                Timestamp reviewedAt = rs.getTimestamp("reviewed_at");
                if (!rs.wasNull()) {
                    shelter.setReviewedAt(reviewedAt);
                }

                shelter.setApprovalMessage(rs.getString("approval_message"));
                shelter.setRejectionReason(rs.getString("rejection_reason"));

                int notificationSent = rs.getInt("notification_sent");
                if (!rs.wasNull()) {
                    shelter.setNotificationSent(notificationSent);
                }

                Timestamp notificationSentAt = rs.getTimestamp("notification_sent_at");
                if (!rs.wasNull()) {
                    shelter.setNotificationSentAt(notificationSentAt);
                }

                shelter.setEmail(rs.getString("email"));
                shelter.setPhone(rs.getString("phone"));

                String profilePhoto = rs.getString("profile_photo_path");
                if (profilePhoto != null && !profilePhoto.isEmpty()) {
                    shelter.setPhotoPath(profilePhoto);
                } else {
                    shelter.setPhotoPath("profile_picture/shelter/default.png");
                }

                shelter.setAvgRating(rs.getDouble("avg_rating"));
                shelter.setReviewCount(rs.getInt("review_count"));

                System.out.println("DEBUG getShelterWithRating: " + shelter.getShelterName() + 
                                 " - Rating: " + shelter.getAvgRating() + 
                                 " - Reviews: " + shelter.getReviewCount());

                return shelter;
            }

        } catch (SQLException e) {
            System.err.println("Error in ShelterDAO.getShelterWithRating(): " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }

        return null;
    }
    
    // Get rating distribution
    public int[] getShelterRatingDistribution(int shelterId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        int[] distribution = new int[5];

        try {
            conn = DatabaseConnection.getConnection();

            for (int i = 0; i < 5; i++) {
                distribution[i] = 0;
            }

            String sql = "SELECT rating, COUNT(*) as count " +
                        "FROM feedback WHERE shelter_id = ? " +
                        "GROUP BY rating ORDER BY rating";

            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            rs = pstmt.executeQuery();

            while (rs.next()) {
                int rating = rs.getInt("rating");
                int count = rs.getInt("count");
                if (rating >= 1 && rating <= 5) {
                    distribution[rating - 1] = count;
                }
            }

            System.out.println("DEBUG: Rating distribution for shelter " + shelterId + 
                              ": " + Arrays.toString(distribution));

        } catch (SQLException e) {
            System.err.println("Error in getShelterRatingDistribution(): " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }

        return distribution;
    }
    
    // NEW METHOD: Add test feedback data
    public void addTestFeedbackData(int shelterId) {
        FeedbackDAO feedbackDAO = new FeedbackDAO();
        java.util.Random random = new java.util.Random();
        
        // Delete existing feedback for this shelter first
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            String deleteSql = "DELETE FROM feedback WHERE shelter_id = ?";
            pstmt = conn.prepareStatement(deleteSql);
            pstmt.setInt(1, shelterId);
            pstmt.executeUpdate();
            pstmt.close();
            
            // Add 10 test feedbacks with random ratings
            for (int i = 1; i <= 10; i++) {
                com.rimba.adopt.model.Feedback feedback = new com.rimba.adopt.model.Feedback();
                feedback.setAdopterId(1); // Assuming adopter ID 1 exists
                feedback.setShelterId(shelterId);
                feedback.setRating(3 + random.nextInt(3)); // Random rating 3-5
                feedback.setComment("Test feedback #" + i + " - This is a test comment.");
                
                feedbackDAO.addFeedback(feedback);
            }
            
            System.out.println("Test feedback data added for shelter ID: " + shelterId);
            
        } catch (SQLException e) {
            System.err.println("Error adding test feedback: " + e.getMessage());
            e.printStackTrace();
        } finally {
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
    }
}