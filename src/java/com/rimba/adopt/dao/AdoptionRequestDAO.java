package com.rimba.adopt.dao;

import com.rimba.adopt.model.AdoptionRequest;
import com.rimba.adopt.model.Adopter; // if needed
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

public class AdoptionRequestDAO {

    private static final Logger logger = Logger.getLogger(AdoptionRequestDAO.class.getName());

    // NEW METHOD: Get requests with FULL details (untuk JSP)
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

    // NEW METHOD: Get single request with full details
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

    // ========== NEW METHODS FOR DASHBOARD SHELTER ==========
// Count requests by status for a shelter
    public Map<String, Integer> countRequestsByStatus(int shelterId) throws SQLException {
        Map<String, Integer> counts = new HashMap<>();

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

// Get monthly request statistics - NEW METHOD
    public Map<String, Object> getMonthlyRequestStats(int shelterId) throws SQLException {
        Map<String, Object> stats = new HashMap<>();

        // Try PostgreSQL syntax first
        String query = "SELECT "
                + "    TO_CHAR(ar.request_date, 'Mon') as month_short, "
                + "    EXTRACT(MONTH FROM ar.request_date) as month_num, "
                + "    ar.status, "
                + "    COUNT(*) as count "
                + "FROM adoption_request ar "
                + "JOIN pets p ON ar.pet_id = p.pet_id "
                + "WHERE p.shelter_id = ? "
                + "    AND EXTRACT(YEAR FROM ar.request_date) = EXTRACT(YEAR FROM CURRENT_DATE) "
                + "GROUP BY TO_CHAR(ar.request_date, 'Mon'), "
                + "         EXTRACT(MONTH FROM ar.request_date), "
                + "         ar.status "
                + "ORDER BY month_num, ar.status";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, shelterId);

            rs = pstmt.executeQuery();

            // Initialize data structures
            List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
            Map<String, int[]> monthlyData = new HashMap<>();

            // Initialize arrays for each status
            monthlyData.put("approved", new int[12]);
            monthlyData.put("pending", new int[12]);
            monthlyData.put("rejected", new int[12]);
            monthlyData.put("cancelled", new int[12]);

            // Initialize all counts to 0
            for (String status : monthlyData.keySet()) {
                for (int i = 0; i < 12; i++) {
                    monthlyData.get(status)[i] = 0;
                }
            }

            // DALAM method getMonthlyRequestStats(), TAMBAH null check:
            while (rs.next()) {
                String monthShort = rs.getString("month_short");
                int monthNum = rs.getInt("month_num") - 1;
                String status = rs.getString("status");
                int count = rs.getInt("count");

                // TAMBAH null check
                if (status != null && monthlyData.containsKey(status.toLowerCase())
                        && monthNum >= 0 && monthNum < 12) {
                    monthlyData.get(status.toLowerCase())[monthNum] = count;
                }
            }

            stats.put("months", months);
            stats.put("monthlyData", monthlyData);

        } catch (SQLException e) {
            // Try MySQL syntax
            try {
                if (rs != null) {
                    rs.close();
                }
                if (pstmt != null) {
                    pstmt.close();
                }

                query = "SELECT "
                        + "    DATE_FORMAT(ar.request_date, '%b') as month_short, "
                        + "    MONTH(ar.request_date) as month_num, "
                        + "    ar.status, "
                        + "    COUNT(*) as count "
                        + "FROM adoption_request ar "
                        + "JOIN pets p ON ar.pet_id = p.pet_id "
                        + "WHERE p.shelter_id = ? "
                        + "    AND YEAR(ar.request_date) = YEAR(CURRENT_DATE()) "
                        + "GROUP BY DATE_FORMAT(ar.request_date, '%b'), "
                        + "         MONTH(ar.request_date), "
                        + "         ar.status "
                        + "ORDER BY month_num, ar.status";

                pstmt = conn.prepareStatement(query);
                pstmt.setInt(1, shelterId);

                rs = pstmt.executeQuery();

                // Re-initialize
                List<String> months = Arrays.asList("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
                Map<String, int[]> monthlyData = new HashMap<>();

                monthlyData.put("approved", new int[12]);
                monthlyData.put("pending", new int[12]);
                monthlyData.put("rejected", new int[12]);
                monthlyData.put("cancelled", new int[12]);

                for (String status : monthlyData.keySet()) {
                    for (int i = 0; i < 12; i++) {
                        monthlyData.get(status)[i] = 0;
                    }
                }

                while (rs.next()) {
                    String monthShort = rs.getString("month_short");
                    int monthNum = rs.getInt("month_num") - 1;
                    String status = rs.getString("status");
                    int count = rs.getInt("count");

                    if (monthlyData.containsKey(status) && monthNum >= 0 && monthNum < 12) {
                        monthlyData.get(status)[monthNum] = count;
                    }
                }

                stats.put("months", months);
                stats.put("monthlyData", monthlyData);

            } catch (SQLException e2) {
                e2.printStackTrace();
                throw e2;
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

        return stats;
    }

// Get recent requests for dashboard - NEW METHOD (optional)
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
        List<AdoptionRequest> requests = new ArrayList<>();
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

}
