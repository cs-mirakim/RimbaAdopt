package com.rimba.adopt.dao;

import com.rimba.adopt.model.AdoptionRequest;
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AdoptionRequestDAO {

    // Get all adoption requests for a specific shelter
    public List<AdoptionRequest> getRequestsByShelter(int shelterId) throws SQLException {
        List<AdoptionRequest> requests = new ArrayList<>();
        String sql = "SELECT ar.*, "
                + "p.name as pet_name, p.species as pet_species, p.breed as pet_breed, "
                + "p.age as pet_age, p.gender as pet_gender, p.health_status as pet_health, "
                + "p.photo_path as pet_photo, "
                + "u.name as adopter_name, u.email as adopter_email, u.phone as adopter_phone, "
                + "u.profile_photo_path as adopter_photo, "
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
                AdoptionRequest request = extractAdoptionRequest(rs);
                requests.add(request);
            }
        }
        return requests;
    }

    // Get pending requests count for a shelter
    public int getPendingCount(int shelterId) throws SQLException {
        String sql = "SELECT COUNT(*) as count FROM adoption_request ar "
                + "JOIN pets p ON ar.pet_id = p.pet_id "
                + "WHERE p.shelter_id = ? AND ar.status = 'pending'";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, shelterId);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                return rs.getInt("count");
            }
        }
        return 0;
    }

    // Get single request by ID with shelter check
    public AdoptionRequest getRequestById(int requestId, int shelterId) throws SQLException {
        String sql = "SELECT ar.*, "
                + "p.name as pet_name, p.species as pet_species, p.breed as pet_breed, "
                + "p.age as pet_age, p.gender as pet_gender, p.health_status as pet_health, "
                + "p.photo_path as pet_photo, "
                + "u.name as adopter_name, u.email as adopter_email, u.phone as adopter_phone, "
                + "u.profile_photo_path as adopter_photo, "
                + "ad.occupation as adopter_occupation, ad.address as adopter_address, "
                + "ad.household_type, ad.has_other_pets, ad.notes as adopter_notes "
                + "FROM adoption_request ar "
                + "JOIN pets p ON ar.pet_id = p.pet_id "
                + "JOIN adopter ad ON ar.adopter_id = ad.adopter_id "
                + "JOIN users u ON ad.adopter_id = u.user_id "
                + "WHERE ar.request_id = ? AND p.shelter_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, requestId);
            pstmt.setInt(2, shelterId);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                return extractAdoptionRequest(rs);
            }
        }
        return null;
    }

    // Update request status (approve/reject)
    public boolean updateRequestStatus(int requestId, String status, String shelterResponse, int shelterId) throws SQLException {
        System.out.println("[DAO DEBUG] updateRequestStatus called with:");
        System.out.println("  requestId: " + requestId);
        System.out.println("  status: " + status);
        System.out.println("  response length: " + shelterResponse.length());
        System.out.println("  shelterId: " + shelterId);

        String sql = "UPDATE adoption_request ar "
                + "SET status = ?, shelter_response = ? "
                + "WHERE ar.request_id = ? "
                + "AND EXISTS (SELECT 1 FROM pets p WHERE p.pet_id = ar.pet_id AND p.shelter_id = ?)";

        System.out.println("[DAO DEBUG] SQL: " + sql);

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, status);
            pstmt.setString(2, shelterResponse);
            pstmt.setInt(3, requestId);
            pstmt.setInt(4, shelterId);

            System.out.println("[DAO DEBUG] Parameters set:");
            System.out.println("  1: " + status);
            System.out.println("  2: " + shelterResponse);
            System.out.println("  3: " + requestId);
            System.out.println("  4: " + shelterId);

            int rowsAffected = pstmt.executeUpdate();
            System.out.println("[DAO DEBUG] Rows affected: " + rowsAffected);

            return rowsAffected > 0;
        }
    }

    // Helper method to extract AdoptionRequest from ResultSet
    private AdoptionRequest extractAdoptionRequest(ResultSet rs) throws SQLException {
        AdoptionRequest request = new AdoptionRequest();

        // Basic adoption request fields
        request.setRequestId(rs.getInt("request_id"));
        request.setAdopterId(rs.getInt("adopter_id"));
        request.setPetId(rs.getInt("pet_id"));
        request.setRequestDate(rs.getTimestamp("request_date"));
        request.setStatus(rs.getString("status"));
        request.setAdopterMessage(rs.getString("adopter_message"));
        request.setShelterResponse(rs.getString("shelter_response"));
        request.setCancellationReason(rs.getString("cancellation_reason"));

        // Store additional fields in a way that can be accessed from JSP
        // We'll store them as request attributes in the servlet
        return request;
    }

    // Cancel request (by adopter)
    public boolean cancelRequest(int requestId, String cancellationReason, int adopterId) throws SQLException {
        String sql = "UPDATE adoption_request SET status = 'cancelled', cancellation_reason = ? "
                + "WHERE request_id = ? AND adopter_id = ? AND status = 'pending'";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, cancellationReason);
            pstmt.setInt(2, requestId);
            pstmt.setInt(3, adopterId);

            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
        }
    }
}
