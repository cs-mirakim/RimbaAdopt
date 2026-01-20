package com.rimba.adopt.dao;

import com.rimba.adopt.model.AdoptionRequest;
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

public class AdoptionRequestDAO {

    private static final Logger logger = Logger.getLogger(AdoptionRequestDAO.class.getName());

    // Create adoption request
    public boolean createAdoptionRequest(AdoptionRequest request) throws SQLException {
        String sql = "INSERT INTO adoption_request (adopter_id, pet_id, shelter_id, adopter_message) "
                + "VALUES (?, ?, ?, ?)";

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            
            // Start transaction
            conn.setAutoCommit(false);
            
            // First, check if pet is still available
            String checkPetSql = "SELECT adoption_status FROM pets WHERE pet_id = ?";
            PreparedStatement checkStmt = conn.prepareStatement(checkPetSql);
            checkStmt.setInt(1, request.getPetId());
            ResultSet rs = checkStmt.executeQuery();
            
            if (!rs.next() || !"available".equals(rs.getString("adoption_status"))) {
                conn.rollback();
                return false; // Pet not available
            }
            
            // Check if adopter already has pending request for this pet
            String checkRequestSql = "SELECT COUNT(*) FROM adoption_request "
                    + "WHERE adopter_id = ? AND pet_id = ? AND status = 'pending'";
            PreparedStatement checkRequestStmt = conn.prepareStatement(checkRequestSql);
            checkRequestStmt.setInt(1, request.getAdopterId());
            checkRequestStmt.setInt(2, request.getPetId());
            ResultSet rs2 = checkRequestStmt.executeQuery();
            
            if (rs2.next() && rs2.getInt(1) > 0) {
                conn.rollback();
                return false; // Already applied
            }
            
            // Create new request
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, request.getAdopterId());
            pstmt.setInt(2, request.getPetId());
            pstmt.setInt(3, request.getShelterId());
            
            if (request.getAdopterMessage() != null && !request.getAdopterMessage().isEmpty()) {
                pstmt.setString(4, request.getAdopterMessage());
            } else {
                pstmt.setNull(4, Types.CLOB);
            }
            
            int affectedRows = pstmt.executeUpdate();
            
            if (affectedRows > 0) {
                conn.commit();
                return true;
            } else {
                conn.rollback();
                return false;
            }
            
        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    logger.log(Level.SEVERE, "Rollback failed", ex);
                }
            }
            logger.log(Level.SEVERE, "Error creating adoption request", e);
            throw e;
        } finally {
            if (pstmt != null) pstmt.close();
            if (conn != null) {
                conn.setAutoCommit(true);
                DatabaseConnection.closeConnection(conn);
            }
        }
    }

    // Get requests with FULL details (untuk JSP)
    public List<Map<String, Object>> getRequestsWithDetails(int shelterId, String filter, String search) throws SQLException {
        List<Map<String, Object>> requests = new ArrayList<>();

        // Base query dengan JOIN untuk dapat semua data
        String baseQuery
                = "SELECT ar.request_id, ar.adopter_id, ar.pet_id, ar.request_date, ar.status, "
                + "       ar.adopter_message, ar.shelter_response, ar.cancellation_reason, "
                + "       p.name as pet_name, p.species, p.breed, p.age, p.gender, p.health_status, p.photo_path as pet_photo, "
                + "       u.name as adopter_name, u.email as adopter_email, u.profile_photo_path as adopter_photo, "
                + "       a.address, a.occupation, a.household_type, a.has_other_pets, a.notes "
                + "FROM adoption_request ar "
                + "JOIN pets p ON ar.pet_id = p.pet_id "
                + "LEFT JOIN adopter a ON ar.adopter_id = a.adopter_id "
                + "JOIN users u ON ar.adopter_id = u.user_id "
                + "WHERE p.shelter_id = ? ";

        StringBuilder query = new StringBuilder(baseQuery);
        List<Object> params = new ArrayList<>();
        params.add(shelterId);

        // Apply filter based on status
        if (filter != null && !filter.equals("all")) {
            query.append(" AND ar.status = ? ");
            params.add(filter);
        }

        // Apply search
        if (search != null && !search.trim().isEmpty()) {
            query.append(" AND (LOWER(p.name) LIKE LOWER(?) OR LOWER(u.name) LIKE LOWER(?)) ");
            String searchPattern = "%" + search + "%";
            params.add(searchPattern);
            params.add(searchPattern);
        }

        query.append(" ORDER BY ar.request_date DESC");

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query.toString());

            // Set parameters
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }

            rs = pstmt.executeQuery();

            while (rs.next()) {
                Map<String, Object> request = new HashMap<>();

                // Basic request info
                request.put("request_id", rs.getInt("request_id"));
                request.put("adopter_id", rs.getInt("adopter_id"));
                request.put("pet_id", rs.getInt("pet_id"));
                request.put("request_date", rs.getTimestamp("request_date"));
                request.put("status", rs.getString("status"));
                request.put("adopter_message", rs.getString("adopter_message"));
                request.put("shelter_response", rs.getString("shelter_response"));
                request.put("cancellation_reason", rs.getString("cancellation_reason"));

                // Pet info
                request.put("pet_name", rs.getString("pet_name"));
                request.put("species", rs.getString("species"));
                request.put("breed", rs.getString("breed"));

                int age = rs.getInt("age");
                request.put("age", rs.wasNull() ? null : age);

                request.put("gender", rs.getString("gender"));
                request.put("health_status", rs.getString("health_status"));
                request.put("pet_photo", rs.getString("pet_photo"));

                // Adopter info
                request.put("adopter_name", rs.getString("adopter_name"));
                request.put("adopter_email", rs.getString("adopter_email"));
                request.put("adopter_photo", rs.getString("adopter_photo"));
                request.put("address", rs.getString("address"));
                request.put("occupation", rs.getString("occupation"));
                request.put("household_type", rs.getString("household_type"));
                request.put("has_other_pets", rs.getInt("has_other_pets"));
                request.put("notes", rs.getString("notes"));

                requests.add(request);
            }

            logger.log(Level.INFO, "Found {0} requests for shelter ID: {1}",
                    new Object[]{requests.size(), shelterId});

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

        return requests;
    }

    // Get single request with full details
    public Map<String, Object> getRequestDetails(int requestId, int shelterId) throws SQLException {
        String query
                = "SELECT ar.request_id, ar.adopter_id, ar.pet_id, ar.request_date, ar.status, "
                + "       ar.adopter_message, ar.shelter_response, ar.cancellation_reason, "
                + "       p.name as pet_name, p.species, p.breed, p.age, p.gender, p.health_status, p.photo_path as pet_photo, "
                + "       u.name as adopter_name, u.email as adopter_email, u.profile_photo_path as adopter_photo, "
                + "       a.address, a.occupation, a.household_type, a.has_other_pets, a.notes "
                + "FROM adoption_request ar "
                + "JOIN pets p ON ar.pet_id = p.pet_id "
                + "LEFT JOIN adopter a ON ar.adopter_id = a.adopter_id "
                + "JOIN users u ON ar.adopter_id = u.user_id "
                + "WHERE ar.request_id = ? AND p.shelter_id = ?";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, requestId);
            pstmt.setInt(2, shelterId);

            rs = pstmt.executeQuery();

            if (rs.next()) {
                Map<String, Object> request = new HashMap<>();

                // Basic request info
                request.put("request_id", rs.getInt("request_id"));
                request.put("adopter_id", rs.getInt("adopter_id"));
                request.put("pet_id", rs.getInt("pet_id"));
                request.put("request_date", rs.getTimestamp("request_date"));
                request.put("status", rs.getString("status"));
                request.put("adopter_message", rs.getString("adopter_message"));
                request.put("shelter_response", rs.getString("shelter_response"));
                request.put("cancellation_reason", rs.getString("cancellation_reason"));

                // Pet info
                request.put("pet_name", rs.getString("pet_name"));
                request.put("species", rs.getString("species"));
                request.put("breed", rs.getString("breed"));

                int age = rs.getInt("age");
                request.put("age", rs.wasNull() ? null : age);

                request.put("gender", rs.getString("gender"));
                request.put("health_status", rs.getString("health_status"));
                request.put("pet_photo", rs.getString("pet_photo"));

                // Adopter info
                request.put("adopter_name", rs.getString("adopter_name"));
                request.put("adopter_email", rs.getString("adopter_email"));
                request.put("adopter_photo", rs.getString("adopter_photo"));
                request.put("address", rs.getString("address"));
                request.put("occupation", rs.getString("occupation"));
                request.put("household_type", rs.getString("household_type"));
                request.put("has_other_pets", rs.getInt("has_other_pets"));
                request.put("notes", rs.getString("notes"));

                return request;
            }

            return null;

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
    }

    // Approve an adoption request (with TRANSACTION)
    public boolean approveRequest(int requestId, int shelterId, String shelterResponse) throws SQLException {
        Connection conn = null;
        PreparedStatement pstmt1 = null;
        PreparedStatement pstmt2 = null;
        PreparedStatement pstmt3 = null;
        PreparedStatement pstmt4 = null; // NEW: untuk update pet status

        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false); // Start transaction

            // 1. Verify this request belongs to this shelter AND is still pending
            String verifyQuery
                    = "SELECT ar.request_id, ar.adopter_id, ar.pet_id "
                    + "FROM adoption_request ar "
                    + "JOIN pets p ON ar.pet_id = p.pet_id "
                    + "WHERE ar.request_id = ? AND p.shelter_id = ? AND ar.status = 'pending'";

            pstmt1 = conn.prepareStatement(verifyQuery);
            pstmt1.setInt(1, requestId);
            pstmt1.setInt(2, shelterId);
            ResultSet rs = pstmt1.executeQuery();

            if (!rs.next()) {
                conn.rollback();
                logger.log(Level.WARNING, "Cannot approve request {0} for shelter {1} - not found or not pending",
                        new Object[]{requestId, shelterId});
                return false;
            }

            int adopterId = rs.getInt("adopter_id");
            int petId = rs.getInt("pet_id");
            rs.close();

            // 2. Update adoption_request status
            String updateRequestQuery
                    = "UPDATE adoption_request SET status = 'approved', shelter_response = ? "
                    + "WHERE request_id = ?";

            pstmt2 = conn.prepareStatement(updateRequestQuery);
            pstmt2.setString(1, shelterResponse);
            pstmt2.setInt(2, requestId);
            int rowsUpdated = pstmt2.executeUpdate();

            if (rowsUpdated != 1) {
                conn.rollback();
                logger.log(Level.WARNING, "Failed to update request {0}", requestId);
                return false;
            }

            // 3. Update other pending requests for same pet to 'rejected'
            String rejectOthersQuery
                    = "UPDATE adoption_request SET status = 'rejected', "
                    + "shelter_response = 'Pet already adopted by another applicant' "
                    + "WHERE pet_id = ? AND status = 'pending' AND request_id != ?";

            pstmt3 = conn.prepareStatement(rejectOthersQuery);
            pstmt3.setInt(1, petId);
            pstmt3.setInt(2, requestId);
            pstmt3.executeUpdate();

            // ========== TAMBAHAN BARU: UPDATE PET STATUS ==========
            String updatePetStatusQuery
                    = "UPDATE pets SET adoption_status = 'adopted' "
                    + "WHERE pet_id = ? AND shelter_id = ?";

            pstmt4 = conn.prepareStatement(updatePetStatusQuery);
            pstmt4.setInt(1, petId);
            pstmt4.setInt(2, shelterId);
            int petRowsUpdated = pstmt4.executeUpdate();

            if (petRowsUpdated != 1) {
                conn.rollback();
                logger.log(Level.WARNING, "Failed to update pet status for pet ID: {0}", petId);
                return false;
            }
            // ========== END TAMBAHAN ==========

            conn.commit();
            logger.log(Level.INFO, "Successfully approved request {0} and updated pet {1} to adopted",
                    new Object[]{requestId, petId});
            return true;

        } catch (SQLException e) {
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException rollbackEx) {
                    logger.log(Level.SEVERE, "Rollback failed", rollbackEx);
                }
            }
            logger.log(Level.SEVERE, "Error approving request", e);
            throw e;
        } finally {
            if (pstmt1 != null) {
                try {
                    pstmt1.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt2 != null) {
                try {
                    pstmt2.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt3 != null) {
                try {
                    pstmt3.close();
                } catch (SQLException e) {
                }
            }
            if (pstmt4 != null) { // NEW: close pstmt4
                try {
                    pstmt4.close();
                } catch (SQLException e) {
                }
            }
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    DatabaseConnection.closeConnection(conn);
                } catch (SQLException e) {
                }
            }
        }
    }

    // Reject an adoption request
    public boolean rejectRequest(int requestId, int shelterId, String shelterResponse) throws SQLException {
        String query
                = "UPDATE adoption_request ar "
                + "SET status = 'rejected', shelter_response = ? "
                + "WHERE ar.request_id = ? "
                + "AND EXISTS (SELECT 1 FROM pets p WHERE p.pet_id = ar.pet_id AND p.shelter_id = ?) "
                + "AND ar.status = 'pending'";

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query);
            pstmt.setString(1, shelterResponse);
            pstmt.setInt(2, requestId);
            pstmt.setInt(3, shelterId);

            int rowsUpdated = pstmt.executeUpdate();

            logger.log(Level.INFO, "Reject request {0} - rows updated: {1}",
                    new Object[]{requestId, rowsUpdated});

            return rowsUpdated > 0;

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

    // Count pending requests for a shelter
    public int countPendingRequests(int shelterId) throws SQLException {
        String query
                = "SELECT COUNT(*) "
                + "FROM adoption_request ar "
                + "JOIN pets p ON ar.pet_id = p.pet_id "
                + "WHERE p.shelter_id = ? AND ar.status = 'pending'";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, shelterId);

            rs = pstmt.executeQuery();

            if (rs.next()) {
                return rs.getInt(1);
            }

            return 0;

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
    }

    // Count requests by status for a shelter
    public Map<String, Integer> countRequestsByStatus(int shelterId) throws SQLException {
        Map<String, Integer> counts = new HashMap<String, Integer>();

        // Initialize dengan semua status
        counts.put("pending", 0);
        counts.put("approved", 0);
        counts.put("rejected", 0);
        counts.put("cancelled", 0);

        String query = "SELECT ar.status, COUNT(*) as count "
                + "FROM adoption_request ar "
                + "JOIN pets p ON ar.pet_id = p.pet_id "
                + "WHERE p.shelter_id = ? "
                + "GROUP BY ar.status";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, shelterId);

            rs = pstmt.executeQuery();

            while (rs.next()) {
                String status = rs.getString("status");
                int count = rs.getInt("count");

                // Gunakan status yang ada dalam result
                if (status != null) {
                    counts.put(status.toLowerCase(), count);
                }
            }

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

        return counts;
    }

    public Map<String, Object> getMonthlyRequestStats(int shelterId) throws SQLException {
        Map<String, Object> stats = new HashMap<String, Object>();

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();

            // Initialize data structures
            List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
            Map<String, int[]> monthlyData = new HashMap<String, int[]>();

            // Initialize arrays for each status
            monthlyData.put("approved", new int[12]);
            monthlyData.put("pending", new int[12]);
            monthlyData.put("rejected", new int[12]);
            monthlyData.put("cancelled", new int[12]);

            // Initialize all counts to 0
            for (String status : monthlyData.keySet()) {
                Arrays.fill(monthlyData.get(status), 0);
            }

            System.out.println("DEBUG DAO: Getting monthly stats for shelter ID: " + shelterId);

            // Simple approach - get all requests for this year and process manually
            String query = "SELECT ar.request_date, ar.status "
                    + "FROM adoption_request ar "
                    + "JOIN pets p ON ar.pet_id = p.pet_id "
                    + "WHERE p.shelter_id = ?";

            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, shelterId);

            rs = pstmt.executeQuery();

            java.util.Calendar cal = java.util.Calendar.getInstance();
            int currentYear = cal.get(java.util.Calendar.YEAR);

            int totalRecords = 0;
            int currentYearRecords = 0;

            while (rs.next()) {
                totalRecords++;
                Timestamp requestDate = rs.getTimestamp("request_date");
                String status = rs.getString("status");

                if (requestDate != null && status != null) {
                    cal.setTime(requestDate);
                    int year = cal.get(java.util.Calendar.YEAR);
                    int month = cal.get(java.util.Calendar.MONTH); // 0-indexed (0=Jan, 11=Dec)

                    // Only process current year data
                    if (year == currentYear && month >= 0 && month < 12) {
                        currentYearRecords++;
                        String statusLower = status.toLowerCase();

                        if (monthlyData.containsKey(statusLower)) {
                            monthlyData.get(statusLower)[month]++;
                            System.out.println("DEBUG DAO: Added " + statusLower + " for month " + month);
                        }
                    }
                }
            }

            System.out.println("DEBUG DAO: Total records found: " + totalRecords);
            System.out.println("DEBUG DAO: Current year records: " + currentYearRecords);
            System.out.println("DEBUG DAO: Approved array: " + Arrays.toString(monthlyData.get("approved")));
            System.out.println("DEBUG DAO: Pending array: " + Arrays.toString(monthlyData.get("pending")));

            stats.put("months", months);
            stats.put("monthlyData", monthlyData);

            return stats;

        } catch (SQLException e) {
            System.err.println("ERROR in getMonthlyRequestStats: " + e.getMessage());
            e.printStackTrace();

            // Return empty but valid structure instead of null
            List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
            Map<String, int[]> monthlyData = new HashMap<String, int[]>();
            monthlyData.put("approved", new int[12]);
            monthlyData.put("pending", new int[12]);
            monthlyData.put("rejected", new int[12]);
            monthlyData.put("cancelled", new int[12]);

            stats.put("months", months);
            stats.put("monthlyData", monthlyData);

            return stats;

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
    }

    public List<Map<String, Object>> getRecentRequests(int shelterId, int limit) throws SQLException {
        List<Map<String, Object>> requests = new ArrayList<>();

        String query = "SELECT ar.request_id, ar.request_date, ar.status, "
                + "       p.name as pet_name, p.photo_path as pet_photo, "
                + "       u.name as adopter_name "
                + "FROM adoption_request ar "
                + "JOIN pets p ON ar.pet_id = p.pet_id "
                + "JOIN users u ON ar.adopter_id = u.user_id "
                + "WHERE p.shelter_id = ? "
                + "ORDER BY ar.request_date DESC "
                + "LIMIT ?";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, shelterId);
            pstmt.setInt(2, limit);

            rs = pstmt.executeQuery();

            while (rs.next()) {
                Map<String, Object> request = new HashMap<>();
                request.put("request_id", rs.getInt("request_id"));
                request.put("request_date", rs.getTimestamp("request_date"));
                request.put("status", rs.getString("status"));
                request.put("pet_name", rs.getString("pet_name"));
                request.put("pet_photo", rs.getString("pet_photo"));
                request.put("adopter_name", rs.getString("adopter_name"));

                requests.add(request);
            }

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

        return requests;
    }

    // OLD METHODS (dipanggil oleh servlet lain mungkin)
    public List<AdoptionRequest> getRequestsByShelter(int shelterId, String filter, String search) throws SQLException {
        // Method lama untuk compatibility
        List<AdoptionRequest> requests = new ArrayList<AdoptionRequest>();
        List<Map<String, Object>> detailedRequests = getRequestsWithDetails(shelterId, filter, search);

        for (Map<String, Object> detailed : detailedRequests) {
            AdoptionRequest request = new AdoptionRequest();
            request.setRequestId((Integer) detailed.get("request_id"));
            request.setAdopterId((Integer) detailed.get("adopter_id"));
            request.setPetId((Integer) detailed.get("pet_id"));
            request.setRequestDate((Timestamp) detailed.get("request_date"));
            request.setStatus((String) detailed.get("status"));
            request.setAdopterMessage((String) detailed.get("adopter_message"));
            request.setShelterResponse((String) detailed.get("shelter_response"));
            request.setCancellationReason((String) detailed.get("cancellation_reason"));

            requests.add(request);
        }

        return requests;
    }

    public AdoptionRequest getRequestById(int requestId, int shelterId) throws SQLException {
        // Method lama untuk compatibility
        Map<String, Object> details = getRequestDetails(requestId, shelterId);

        if (details == null) {
            return null;
        }

        AdoptionRequest request = new AdoptionRequest();
        request.setRequestId((Integer) details.get("request_id"));
        request.setAdopterId((Integer) details.get("adopter_id"));
        request.setPetId((Integer) details.get("pet_id"));
        request.setRequestDate((Timestamp) details.get("request_date"));
        request.setStatus((String) details.get("status"));
        request.setAdopterMessage((String) details.get("adopter_message"));
            request.setShelterResponse((String) details.get("shelter_response"));
            request.setCancellationReason((String) details.get("cancellation_reason"));

            return request;
        }

        // Get adoption statistics for adopter
    public Map<String, Integer> getAdoptionStatsByAdopter(int adopterId) throws SQLException {
        Map<String, Integer> stats = new HashMap<String, Integer>();
        
        // Initialize with all statuses
        String[] statuses = {"pending", "approved", "rejected", "cancelled"};
        for (String status : statuses) {
            stats.put(status, 0);
        }
        
        String query = "SELECT status, COUNT(*) as count " +
                       "FROM adoption_request " +
                       "WHERE adopter_id = ? " +
                       "GROUP BY status";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(query)) {
            
            pstmt.setInt(1, adopterId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    String status = rs.getString("status");
                    int count = rs.getInt("count");
                    if (status != null) {
                        stats.put(status.toLowerCase(), count);
                    }
                }
            }
        }
        
        // Calculate total
        int total = stats.values().stream().mapToInt(Integer::intValue).sum();
        stats.put("total", total);
        
        return stats;
    }

    // Get monthly adoption stats for adopter
    public Map<String, List<Integer>> getMonthlyAdoptionStatsByAdopter(int adopterId) throws SQLException {
        Map<String, List<Integer>> monthlyStats = new HashMap<String, List<Integer>>();
        
        // Initialize arrays for each status (12 months)
        String[] statuses = {"approved", "pending", "rejected", "cancelled"};
        for (String status : statuses) {
            List<Integer> monthlyData = new ArrayList<Integer>(Collections.nCopies(12, 0));
            monthlyStats.put(status, monthlyData);
        }
        
        String query = "SELECT MONTH(request_date) as month, status, COUNT(*) as count " +
                       "FROM adoption_request " +
                       "WHERE adopter_id = ? AND YEAR(request_date) = YEAR(CURDATE()) " +
                       "GROUP BY MONTH(request_date), status " +
                       "ORDER BY month";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(query)) {
            
            pstmt.setInt(1, adopterId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    int month = rs.getInt("month") - 1; // Convert to 0-indexed
                    String status = rs.getString("status");
                    int count = rs.getInt("count");
                    
                    if (month >= 0 && month < 12 && status != null) {
                        String statusLower = status.toLowerCase();
                        if (monthlyStats.containsKey(statusLower)) {
                            List<Integer> monthlyData = monthlyStats.get(statusLower);
                            monthlyData.set(month, count);
                        }
                    }
                }
            }
        }
        
        return monthlyStats;
    }

    // Get adoption applications for adopter
    public List<Map<String, Object>> getApplicationsByAdopter(int adopterId) throws SQLException {
        List<Map<String, Object>> applications = new ArrayList<Map<String, Object>>();
        
        String query = "SELECT ar.request_id, ar.request_date, ar.status, "
                     + "       ar.adopter_message, ar.shelter_response, ar.cancellation_reason, "
                     + "       p.pet_id, p.name as pet_name, p.species, p.breed, p.age, p.gender, "
                     + "       p.health_status, p.photo_path as pet_photo, "
                     + "       s.shelter_name, s.shelter_address, "
                     + "       a.address, a.occupation, a.household_type, a.has_other_pets, a.notes "
                     + "FROM adoption_request ar "
                     + "JOIN pets p ON ar.pet_id = p.pet_id "
                     + "JOIN shelter s ON p.shelter_id = s.shelter_id "
                     + "LEFT JOIN adopter a ON ar.adopter_id = a.adopter_id "
                     + "WHERE ar.adopter_id = ? "
                     + "ORDER BY ar.request_date DESC";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, adopterId);
            
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Map<String, Object> application = new HashMap<String, Object>();
                
                // Basic request info
                application.put("request_id", rs.getInt("request_id"));
                application.put("request_date", rs.getTimestamp("request_date"));
                application.put("status", rs.getString("status"));
                application.put("adopter_message", rs.getString("adopter_message"));
                application.put("shelter_response", rs.getString("shelter_response"));
                application.put("cancellation_reason", rs.getString("cancellation_reason"));
                
                // Pet info
                application.put("pet_id", rs.getInt("pet_id"));
                application.put("pet_name", rs.getString("pet_name"));
                application.put("species", rs.getString("species"));
                application.put("breed", rs.getString("breed"));
                application.put("age", rs.getInt("age"));
                application.put("gender", rs.getString("gender"));
                application.put("health_status", rs.getString("health_status"));
                application.put("pet_photo", rs.getString("pet_photo"));
                
                // Shelter info
                application.put("shelter_name", rs.getString("shelter_name"));
                application.put("shelter_address", rs.getString("shelter_address"));
                
                // Adopter info
                application.put("address", rs.getString("address"));
                application.put("occupation", rs.getString("occupation"));
                application.put("household_type", rs.getString("household_type"));
                application.put("has_other_pets", rs.getInt("has_other_pets"));
                application.put("notes", rs.getString("notes"));
                
                applications.add(application);
            }
            
            logger.log(Level.INFO, "Found {0} applications for adopter ID: {1}",
                    new Object[]{applications.size(), adopterId});
            
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
        
        return applications;
    }

    // Cancel adoption request for adopter
    public boolean cancelRequestByAdopter(int requestId, int adopterId, String cancellationReason) throws SQLException {
        String query = "UPDATE adoption_request "
                     + "SET status = 'cancelled', cancellation_reason = ?, request_date = CURRENT_TIMESTAMP "
                     + "WHERE request_id = ? AND adopter_id = ? AND status = 'pending'";

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query);
            pstmt.setString(1, cancellationReason);
            pstmt.setInt(2, requestId);
            pstmt.setInt(3, adopterId);

            int rowsUpdated = pstmt.executeUpdate();

            logger.log(Level.INFO, "Cancel request {0} by adopter {1} - rows updated: {2}",
                    new Object[]{requestId, adopterId, rowsUpdated});

            return rowsUpdated > 0;

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
}