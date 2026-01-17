package com.rimba.adopt.dao;

import com.rimba.adopt.model.Shelter;
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ShelterDAO {

    // Get all approved shelters
    public List<Shelter> getAllApprovedShelters() {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        List<Shelter> shelters = new ArrayList<Shelter>(); // Explicit type
        
        try {
            conn = DatabaseConnection.getConnection();
            
            String sql = "SELECT s.*, u.email, u.phone " +
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
                
                // Handle possible NULL values
                int reviewedBy = rs.getInt("reviewed_by");
                if (!rs.wasNull()) {
                    shelter.setReviewedBy(reviewedBy);
                }
                
                shelter.setEmail(rs.getString("email"));
                shelter.setPhone(rs.getString("phone"));
                
                // Default photo
                shelter.setPhotoPath("profile_picture/shelter/default.png");
                
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
            String sql = "SELECT s.*, u.email, u.phone " +
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
                
                // Handle NULL values
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
                
                // Default photo
                shelter.setPhotoPath("profile_picture/shelter/default.png");
                
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

    // Get shelters with rating
    public List<Shelter> getSheltersForPublic() {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        List<Shelter> shelters = new ArrayList<Shelter>(); // Explicit type
        
        try {
            conn = DatabaseConnection.getConnection();
            
            String sql = "SELECT s.*, u.email, u.phone, " +
                        "COALESCE(AVG(f.rating), 0) as avg_rating, " +
                        "COUNT(f.feedback_id) as review_count " +
                        "FROM shelter s " +
                        "JOIN users u ON s.shelter_id = u.user_id " +
                        "LEFT JOIN feedback f ON s.shelter_id = f.shelter_id " +
                        "WHERE s.approval_status = 'approved' " +
                        "GROUP BY s.shelter_id, s.shelter_name, s.shelter_address, " +
                        "s.shelter_description, s.website, s.operating_hours, " +
                        "s.approval_status, u.email, u.phone " +
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
                shelter.setEmail(rs.getString("email"));
                shelter.setPhone(rs.getString("phone"));
                shelter.setAvgRating(rs.getDouble("avg_rating"));
                shelter.setReviewCount(rs.getInt("review_count"));
                shelter.setPhotoPath("profile_picture/shelter/default.png");
                
                shelters.add(shelter);
            }
            
        } catch (SQLException e) {
            System.err.println("Error in ShelterDAO.getSheltersForPublic(): " + e.getMessage());
            e.printStackTrace();
            // Fallback
            return getAllApprovedShelters();
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException e) {}
            if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
            DatabaseConnection.closeConnection(conn);
        }
        
        return shelters;
    }
}