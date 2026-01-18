package com.rimba.adopt.dao;

import com.rimba.adopt.model.Users;
import com.rimba.adopt.model.Shelter;
import com.rimba.adopt.model.Adopter;
import com.rimba.adopt.model.Admin;
import java.sql.*;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

public class UsersDao {

    private static final Logger logger = Logger.getLogger(UsersDao.class.getName());
    private Connection connection;

    public UsersDao(Connection connection) {
        this.connection = connection;
    }

    // Check email exists
    public boolean isEmailExists(String email) throws SQLException {
        String sql = "SELECT COUNT(*) FROM users WHERE email = ?";
        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, email);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error checking email existence", e);
            throw e;
        }
        return false;
    }

    // Create user (basic info)
    public int createUser(Users user) throws SQLException {
        // Derby menggunakan IDENTITY column, jadi pakai syntax ini
        String sql = "INSERT INTO users (name, email, password, phone, role, profile_photo_path) "
                + "VALUES (?, ?, ?, ?, ?, ?)";

        try (PreparedStatement stmt = connection.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            stmt.setString(1, user.getName());
            stmt.setString(2, user.getEmail());
            stmt.setString(3, user.getPassword());
            stmt.setString(4, user.getPhone());
            stmt.setString(5, user.getRole());

            // Handle nullable profile photo
            if (user.getProfilePhotoPath() != null) {
                stmt.setString(6, user.getProfilePhotoPath());
            } else {
                stmt.setNull(6, Types.VARCHAR);
            }

            int affectedRows = stmt.executeUpdate();

            if (affectedRows == 0) {
                throw new SQLException("Creating user failed, no rows affected.");
            }

            // Get generated user_id
            try (ResultSet generatedKeys = stmt.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    int userId = generatedKeys.getInt(1);
                    logger.info("Generated user ID: " + userId);
                    return userId;
                } else {
                    throw new SQLException("Creating user failed, no ID obtained.");
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error creating user", e);
            throw e;
        }
    }

    // Create shelter
    public boolean createShelter(Shelter shelter, int userId) throws SQLException {
        String sql = "INSERT INTO shelter (shelter_id, shelter_name, shelter_address, "
                + "shelter_description, website, operating_hours, approval_status) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, shelter.getShelterName());
            stmt.setString(3, shelter.getShelterAddress());

            // Handle nullable description
            if (shelter.getShelterDescription() != null && !shelter.getShelterDescription().isEmpty()) {
                stmt.setString(4, shelter.getShelterDescription());
            } else {
                stmt.setNull(4, Types.CLOB);
            }

            // Handle nullable website
            if (shelter.getWebsite() != null && !shelter.getWebsite().isEmpty()) {
                stmt.setString(5, shelter.getWebsite());
            } else {
                stmt.setNull(5, Types.VARCHAR);
            }

            stmt.setString(6, shelter.getOperatingHours());
            stmt.setString(7, "pending"); // Always set to pending

            int result = stmt.executeUpdate();
            logger.info("Shelter created with result: " + result);
            return result > 0;
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error creating shelter", e);
            throw e;
        }
    }

    // Create adopter
    public boolean createAdopter(Adopter adopter, int userId) throws SQLException {
        String sql = "INSERT INTO adopter (adopter_id, address, occupation, "
                + "household_type, has_other_pets, notes) "
                + "VALUES (?, ?, ?, ?, ?, ?)";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            stmt.setString(2, adopter.getAddress());
            stmt.setString(3, adopter.getOccupation());
            stmt.setString(4, adopter.getHouseholdType());
            stmt.setInt(5, adopter.getHasOtherPets() != null ? adopter.getHasOtherPets() : 0);

            // Handle nullable notes
            if (adopter.getNotes() != null && !adopter.getNotes().isEmpty()) {
                stmt.setString(6, adopter.getNotes());
            } else {
                stmt.setNull(6, Types.CLOB);
            }

            int result = stmt.executeUpdate();
            logger.info("Adopter created with result: " + result);
            return result > 0;
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error creating adopter", e);
            throw e;
        }
    }

    // Get user by email (untuk login)
    public Users getUserByEmail(String email) throws SQLException {
        String sql = "SELECT * FROM users WHERE email = ?";
        Users user = null;

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, email);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    user = new Users();
                    user.setUserId(rs.getInt("user_id"));
                    user.setName(rs.getString("name"));
                    user.setEmail(rs.getString("email"));
                    user.setPassword(rs.getString("password"));
                    user.setPhone(rs.getString("phone"));
                    user.setRole(rs.getString("role"));
                    user.setProfilePhotoPath(rs.getString("profile_photo_path"));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                }
            }
        }
        return user;
    }

    // Additional useful methods
    public Users getUserById(int userId) throws SQLException {
        String sql = "SELECT * FROM users WHERE user_id = ?";
        Users user = null;

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    user = new Users();
                    user.setUserId(rs.getInt("user_id"));
                    user.setName(rs.getString("name"));
                    user.setEmail(rs.getString("email"));
                    user.setPassword(rs.getString("password"));
                    user.setPhone(rs.getString("phone"));
                    user.setRole(rs.getString("role"));
                    user.setProfilePhotoPath(rs.getString("profile_photo_path"));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                }
            }
        }
        return user;
    }

    // UsersDao.java - TAMBAH methods ini di hujung class
// ========== GET FULL USER PROFILE ==========
    public Map<String, Object> getFullUserProfile(int userId) throws SQLException {
        Map<String, Object> profileData = new HashMap<>();

        // 1. Get user basic info
        Users user = getUserById(userId);
        if (user == null) {
            return null;
        }

        profileData.put("user", user);

        // 2. Get role-specific data
        String role = user.getRole();

        if ("shelter".equals(role)) {
            String sql = "SELECT * FROM shelter WHERE shelter_id = ?";
            try (PreparedStatement stmt = connection.prepareStatement(sql)) {
                stmt.setInt(1, userId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        Shelter shelter = new Shelter();
                        shelter.setShelterName(rs.getString("shelter_name"));
                        shelter.setShelterAddress(rs.getString("shelter_address"));
                        shelter.setShelterDescription(rs.getString("shelter_description"));
                        shelter.setWebsite(rs.getString("website"));
                        shelter.setOperatingHours(rs.getString("operating_hours"));
                        shelter.setApprovalStatus(rs.getString("approval_status"));
                        profileData.put("shelter", shelter);
                    }
                }
            }

        } else if ("adopter".equals(role)) {
            String sql = "SELECT * FROM adopter WHERE adopter_id = ?";
            try (PreparedStatement stmt = connection.prepareStatement(sql)) {
                stmt.setInt(1, userId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        Adopter adopter = new Adopter();
                        adopter.setAddress(rs.getString("address"));
                        adopter.setOccupation(rs.getString("occupation"));
                        adopter.setHouseholdType(rs.getString("household_type"));
                        adopter.setHasOtherPets(rs.getInt("has_other_pets"));
                        adopter.setNotes(rs.getString("notes"));
                        profileData.put("adopter", adopter);
                    }
                }
            }

        } // BEFORE (Line lebih kurang 180-190)
        else if ("admin".equals(role)) {
            String sql = "SELECT * FROM admin WHERE admin_id = ?";
            try (PreparedStatement stmt = connection.prepareStatement(sql)) {
                stmt.setInt(1, userId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        // GANTI Map dengan Admin Object  ← BETULKAN INI
                        Admin admin = new Admin();
                        admin.setAdminId(rs.getInt("admin_id"));
                        admin.setPosition(rs.getString("position"));
                        profileData.put("admin", admin);  // ← BETUL!
                    }
                }
            }
        }

        return profileData;
    }

// ========== UPDATE USER (TANPA PASSWORD) ==========
    public boolean updateUser(Users user) throws SQLException {
        String sql = "UPDATE users SET name = ?, email = ?, phone = ?, profile_photo_path = ? WHERE user_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, user.getName());
            stmt.setString(2, user.getEmail());
            stmt.setString(3, user.getPhone());

            // Handle profile photo path
            if (user.getProfilePhotoPath() != null && !user.getProfilePhotoPath().isEmpty()) {
                stmt.setString(4, user.getProfilePhotoPath());
            } else {
                stmt.setNull(4, Types.VARCHAR);
            }

            stmt.setInt(5, user.getUserId());

            int rowsUpdated = stmt.executeUpdate();
            logger.info("Updated user ID " + user.getUserId() + " (without password), Rows: " + rowsUpdated);
            return rowsUpdated > 0;
        }
    }

// ========== UPDATE PASSWORD SAHAJA ==========
    public boolean updatePassword(int userId, String hashedPassword) throws SQLException {
        String sql = "UPDATE users SET password = ? WHERE user_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, hashedPassword);
            stmt.setInt(2, userId);

            int rowsUpdated = stmt.executeUpdate();
            logger.info("Updated password for user ID " + userId + ", Rows: " + rowsUpdated);
            return rowsUpdated > 0;
        }
    }
// ========== UPDATE SHELTER ==========

    public boolean updateShelter(Shelter shelter, int userId) throws SQLException {
        String sql = "UPDATE shelter SET shelter_name = ?, shelter_address = ?, "
                + "shelter_description = ?, website = ?, operating_hours = ? "
                + "WHERE shelter_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, shelter.getShelterName());
            stmt.setString(2, shelter.getShelterAddress());

            if (shelter.getShelterDescription() != null && !shelter.getShelterDescription().isEmpty()) {
                stmt.setString(3, shelter.getShelterDescription());
            } else {
                stmt.setNull(3, Types.CLOB);
            }

            if (shelter.getWebsite() != null && !shelter.getWebsite().isEmpty()) {
                stmt.setString(4, shelter.getWebsite());
            } else {
                stmt.setNull(4, Types.VARCHAR);
            }

            stmt.setString(5, shelter.getOperatingHours());
            stmt.setInt(6, userId);

            int rowsUpdated = stmt.executeUpdate();
            logger.info("Updated shelter for user ID " + userId + ", Rows: " + rowsUpdated);
            return rowsUpdated > 0;
        }
    }

// ========== UPDATE ADOPTER ==========
    public boolean updateAdopter(Adopter adopter, int userId) throws SQLException {
        String sql = "UPDATE adopter SET address = ?, occupation = ?, household_type = ?, "
                + "has_other_pets = ?, notes = ? WHERE adopter_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, adopter.getAddress());
            stmt.setString(2, adopter.getOccupation());
            stmt.setString(3, adopter.getHouseholdType());
            stmt.setInt(4, adopter.getHasOtherPets() != null ? adopter.getHasOtherPets() : 0);

            if (adopter.getNotes() != null && !adopter.getNotes().isEmpty()) {
                stmt.setString(5, adopter.getNotes());
            } else {
                stmt.setNull(5, Types.CLOB);
            }

            stmt.setInt(6, userId);

            int rowsUpdated = stmt.executeUpdate();
            logger.info("Updated adopter for user ID " + userId + ", Rows: " + rowsUpdated);
            return rowsUpdated > 0;
        }
    }

// ========== UPDATE ADMIN ==========
    public boolean updateAdmin(Admin admin) throws SQLException {  // ← Terima Admin object
        String sql = "UPDATE admin SET position = ? WHERE admin_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            if (admin.getPosition() != null && !admin.getPosition().isEmpty()) {
                stmt.setString(1, admin.getPosition());
            } else {
                stmt.setNull(1, Types.VARCHAR);
            }

            stmt.setInt(2, admin.getAdminId());

            int rowsUpdated = stmt.executeUpdate();
            logger.info("Updated admin ID " + admin.getAdminId() + ", Rows: " + rowsUpdated);
            return rowsUpdated > 0;
        }
    }

// ========== DELETE USER (MANUAL CASCADE) ==========
    public boolean deleteUser(int userId) throws SQLException {
        // Apache Derby TIDAK support ON DELETE CASCADE, jadi perlu delete manual
        String role = null;
        String profilePhotoPath = null;

        // 1. Dapatkan role user
        String getInfoSql = "SELECT role, profile_photo_path FROM users WHERE user_id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(getInfoSql)) {
            stmt.setInt(1, userId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    role = rs.getString("role");
                    profilePhotoPath = rs.getString("profile_photo_path");
                }
            }
        }

        // 2. Hapus dari tabel dependen berdasarkan role
        try {
            // Hapus dari tabel dependen terlebih dahulu
            if ("shelter".equals(role)) {
                // Hapus data yang terkait dengan shelter (dalam urutan yang benar)

                // Pertama, hapus pets yang dimiliki shelter ini
                String deletePetsSql = "DELETE FROM pets WHERE shelter_id = ?";
                try (PreparedStatement stmt = connection.prepareStatement(deletePetsSql)) {
                    stmt.setInt(1, userId);
                    stmt.executeUpdate();
                }

                // Hapus feedback untuk shelter ini
                String deleteFeedbackSql = "DELETE FROM feedback WHERE shelter_id = ?";
                try (PreparedStatement stmt = connection.prepareStatement(deleteFeedbackSql)) {
                    stmt.setInt(1, userId);
                    stmt.executeUpdate();
                }

                // Hapus dari shelter table
                String deleteShelterSql = "DELETE FROM shelter WHERE shelter_id = ?";
                try (PreparedStatement stmt = connection.prepareStatement(deleteShelterSql)) {
                    stmt.setInt(1, userId);
                    stmt.executeUpdate();
                }

            } else if ("adopter".equals(role)) {
                // Hapus data yang terkait dengan adopter

                // Hapus adoption records terlebih dahulu
                String deleteAdoptionRecordsSql = "DELETE FROM adoption_record WHERE adopter_id = ?";
                try (PreparedStatement stmt = connection.prepareStatement(deleteAdoptionRecordsSql)) {
                    stmt.setInt(1, userId);
                    stmt.executeUpdate();
                }

                // Hapus adoption requests
                String deleteAdoptionRequestsSql = "DELETE FROM adoption_request WHERE adopter_id = ?";
                try (PreparedStatement stmt = connection.prepareStatement(deleteAdoptionRequestsSql)) {
                    stmt.setInt(1, userId);
                    stmt.executeUpdate();
                }

                // Hapus lost reports
                String deleteLostReportsSql = "DELETE FROM lost_report WHERE adopter_id = ?";
                try (PreparedStatement stmt = connection.prepareStatement(deleteLostReportsSql)) {
                    stmt.setInt(1, userId);
                    stmt.executeUpdate();
                }

                // Hapus feedback dari adopter
                String deleteFeedbackSql = "DELETE FROM feedback WHERE adopter_id = ?";
                try (PreparedStatement stmt = connection.prepareStatement(deleteFeedbackSql)) {
                    stmt.setInt(1, userId);
                    stmt.executeUpdate();
                }

                // Hapus dari adopter table
                String deleteAdopterSql = "DELETE FROM adopter WHERE adopter_id = ?";
                try (PreparedStatement stmt = connection.prepareStatement(deleteAdopterSql)) {
                    stmt.setInt(1, userId);
                    stmt.executeUpdate();
                }

            } else if ("admin".equals(role)) {
                // Hapus dari admin table
                String deleteAdminSql = "DELETE FROM admin WHERE admin_id = ?";
                try (PreparedStatement stmt = connection.prepareStatement(deleteAdminSql)) {
                    stmt.setInt(1, userId);
                    stmt.executeUpdate();
                }

                // Hapus data banner yang dibuat admin (optional, jika mau cascade)
                String updateBannerSql = "UPDATE awareness_banner SET created_by = NULL WHERE created_by = ?";
                try (PreparedStatement stmt = connection.prepareStatement(updateBannerSql)) {
                    stmt.setInt(1, userId);
                    stmt.executeUpdate();
                }

                // Update shelter reviewed_by menjadi NULL
                String updateShelterReviewSql = "UPDATE shelter SET reviewed_by = NULL WHERE reviewed_by = ?";
                try (PreparedStatement stmt = connection.prepareStatement(updateShelterReviewSql)) {
                    stmt.setInt(1, userId);
                    stmt.executeUpdate();
                }
            }

            // 3. Hapus password reset tokens
            String deleteTokensSql = "DELETE FROM password_reset_tokens WHERE user_id = ?";
            try (PreparedStatement stmt = connection.prepareStatement(deleteTokensSql)) {
                stmt.setInt(1, userId);
                stmt.executeUpdate();
            }

            // 4. Akhirnya, hapus dari users table
            String deleteUserSql = "DELETE FROM users WHERE user_id = ?";
            try (PreparedStatement stmt = connection.prepareStatement(deleteUserSql)) {
                stmt.setInt(1, userId);
                int rowsDeleted = stmt.executeUpdate();

                logger.info("Deleted user ID " + userId + " (role: " + role + "), Rows: " + rowsDeleted);
                return rowsDeleted > 0;
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error deleting user with ID: " + userId, e);
            throw e;
        }
    }
    // UsersDao.java - TAMBAH methods ini di hujung class, SEBELUM tutup kurungan }

// ========== GET PENDING SHELTER REGISTRATIONS ==========
    public List<Map<String, Object>> getPendingShelters() throws SQLException {
        List<Map<String, Object>> pendingShelters = new ArrayList<>();

        String sql = "SELECT u.user_id, u.name, u.email, u.phone, u.created_at, "
                + "s.shelter_name, s.shelter_address, s.shelter_description, "
                + "s.approval_status, s.reviewed_by, s.reviewed_at, s.rejection_reason "
                + "FROM users u "
                + "JOIN shelter s ON u.user_id = s.shelter_id "
                + "WHERE s.approval_status = 'pending' "
                + "ORDER BY u.created_at DESC";

        try (PreparedStatement stmt = connection.prepareStatement(sql);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> shelter = new HashMap<>();
                shelter.put("id", "SHT-" + rs.getInt("user_id"));
                shelter.put("userId", rs.getInt("user_id"));
                shelter.put("name", rs.getString("shelter_name"));
                shelter.put("email", rs.getString("email"));
                shelter.put("type", "Shelter");
                shelter.put("date", rs.getTimestamp("created_at").toLocalDateTime().toLocalDate().toString());
                shelter.put("status", "pending");
                shelter.put("phone", rs.getString("phone"));
                shelter.put("address", rs.getString("shelter_address"));
                shelter.put("description", rs.getString("shelter_description"));
                shelter.put("rejectionReason", rs.getString("rejection_reason"));
                shelter.put("reviewedBy", rs.getString("reviewed_by"));
                shelter.put("reviewedAt", rs.getTimestamp("reviewed_at"));

                pendingShelters.add(shelter);
            }
        }

        return pendingShelters;
    }

// ========== GET ALL REGISTRATIONS FOR REVIEW ==========
    public List<Map<String, Object>> getAllRegistrationsForReview() throws SQLException {
        List<Map<String, Object>> registrations = new ArrayList<>();

        // Get shelters
        String shelterSql = "SELECT u.user_id, u.name, u.email, u.phone, u.created_at, "
                + "s.shelter_name, s.shelter_address, s.shelter_description, "
                + "s.approval_status, s.reviewed_by, s.reviewed_at, s.rejection_reason, "
                + "s.approval_message "
                + "FROM users u "
                + "JOIN shelter s ON u.user_id = s.shelter_id "
                + "ORDER BY u.created_at DESC";

        try (PreparedStatement stmt = connection.prepareStatement(shelterSql);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> registration = new HashMap<>();
                registration.put("id", "SHT-" + rs.getInt("user_id"));
                registration.put("userId", rs.getInt("user_id"));
                registration.put("name", rs.getString("shelter_name"));
                registration.put("email", rs.getString("email"));
                registration.put("type", "Shelter");
                registration.put("date", rs.getTimestamp("created_at").toLocalDateTime().toLocalDate().toString());

                String approvalStatus = rs.getString("approval_status");
                registration.put("status", approvalStatus);

                registration.put("phone", rs.getString("phone"));
                registration.put("address", rs.getString("shelter_address"));
                registration.put("description", rs.getString("shelter_description"));
                registration.put("rejectionReason", rs.getString("rejection_reason"));
                registration.put("approvalMessage", rs.getString("approval_message"));
                registration.put("reviewedBy", rs.getString("reviewed_by"));
                registration.put("reviewedAt", rs.getTimestamp("reviewed_at"));

                registrations.add(registration);
            }
        }

        // Get adopters (auto approved - show as "approved" status)
        String adopterSql = "SELECT u.user_id, u.name, u.email, u.phone, u.created_at, "
                + "a.address, a.occupation, a.household_type "
                + "FROM users u "
                + "JOIN adopter a ON u.user_id = a.adopter_id "
                + "ORDER BY u.created_at DESC";

        try (PreparedStatement stmt = connection.prepareStatement(adopterSql);
                ResultSet rs = stmt.executeQuery()) {

            while (rs.next()) {
                Map<String, Object> registration = new HashMap<>();
                registration.put("id", "USR-" + rs.getInt("user_id"));
                registration.put("userId", rs.getInt("user_id"));
                registration.put("name", rs.getString("name"));
                registration.put("email", rs.getString("email"));
                registration.put("type", "Adopter");
                registration.put("date", rs.getTimestamp("created_at").toLocalDateTime().toLocalDate().toString());
                registration.put("status", "approved"); // Adopters are auto-approved
                registration.put("phone", rs.getString("phone"));
                registration.put("address", rs.getString("address"));
                registration.put("occupation", rs.getString("occupation"));
                registration.put("householdType", rs.getString("household_type"));

                registrations.add(registration);
            }
        }

        return registrations;
    }

// ========== APPROVE SHELTER ==========
    public boolean approveShelter(int shelterId, int adminId, String approvalMessage) throws SQLException {
        String sql = "UPDATE shelter SET approval_status = 'approved', "
                + "reviewed_by = ?, reviewed_at = CURRENT_TIMESTAMP, "
                + "approval_message = ?, rejection_reason = NULL, "
                + "notification_sent = 0, notification_sent_at = NULL "
                + "WHERE shelter_id = ? AND approval_status = 'pending'";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, adminId);
            stmt.setString(2, approvalMessage);
            stmt.setInt(3, shelterId);

            int rowsUpdated = stmt.executeUpdate();
            logger.info("Approved shelter ID: " + shelterId + " by admin ID: " + adminId);
            return rowsUpdated > 0;
        }
    }

// ========== REJECT SHELTER ==========
    public boolean rejectShelter(int shelterId, int adminId, String rejectionReason) throws SQLException {
        String sql = "UPDATE shelter SET approval_status = 'rejected', "
                + "reviewed_by = ?, reviewed_at = CURRENT_TIMESTAMP, "
                + "rejection_reason = ?, approval_message = NULL, "
                + "notification_sent = 0, notification_sent_at = NULL "
                + "WHERE shelter_id = ? AND approval_status = 'pending'";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setInt(1, adminId);
            stmt.setString(2, rejectionReason);
            stmt.setInt(3, shelterId);

            int rowsUpdated = stmt.executeUpdate();
            logger.info("Rejected shelter ID: " + shelterId + " by admin ID: " + adminId);
            return rowsUpdated > 0;
        }
    }

// ========== GET APPROVAL STATISTICS ==========
    public Map<String, Object> getApprovalStatistics() throws SQLException {
        Map<String, Object> stats = new HashMap<>();

        // Total pending shelters
        String pendingSql = "SELECT COUNT(*) as count FROM shelter WHERE approval_status = 'pending'";
        try (PreparedStatement stmt = connection.prepareStatement(pendingSql);
                ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                stats.put("pendingCount", rs.getInt("count"));
            }
        }

        // Approved today
        String approvedTodaySql = "SELECT COUNT(*) as count FROM shelter "
                + "WHERE approval_status = 'approved' "
                + "AND DATE(reviewed_at) = CURRENT_DATE";
        try (PreparedStatement stmt = connection.prepareStatement(approvedTodaySql);
                ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                stats.put("approvedToday", rs.getInt("count"));
            }
        }

        // Rejected today
        String rejectedTodaySql = "SELECT COUNT(*) as count FROM shelter "
                + "WHERE approval_status = 'rejected' "
                + "AND DATE(reviewed_at) = CURRENT_DATE";
        try (PreparedStatement stmt = connection.prepareStatement(rejectedTodaySql);
                ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                stats.put("rejectedToday", rs.getInt("count"));
            }
        }

        // Total approved
        String totalApprovedSql = "SELECT COUNT(*) as count FROM shelter WHERE approval_status = 'approved'";
        try (PreparedStatement stmt = connection.prepareStatement(totalApprovedSql);
                ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                stats.put("totalApproved", rs.getInt("count"));
            }
        }

        // Total rejected
        String totalRejectedSql = "SELECT COUNT(*) as count FROM shelter WHERE approval_status = 'rejected'";
        try (PreparedStatement stmt = connection.prepareStatement(totalRejectedSql);
                ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                stats.put("totalRejected", rs.getInt("count"));
            }
        }

        // Calculate rejection rate
        int totalProcessed = ((Number) stats.getOrDefault("totalApproved", 0)).intValue()
                + ((Number) stats.getOrDefault("totalRejected", 0)).intValue();

        double rejectionRate = 0;
        if (totalProcessed > 0) {
            rejectionRate = (((Number) stats.getOrDefault("totalRejected", 0)).doubleValue() / totalProcessed) * 100;
        }
        stats.put("rejectionRate", Math.round(rejectionRate * 100.0) / 100.0);

        return stats;
    }
    // ========== GET RECENT ACTIVITY ==========
public List<Map<String, Object>> getRecentActivity(int limit) throws SQLException {
    List<Map<String, Object>> activities = new ArrayList<>();
    
    String sql = "SELECT s.shelter_id, s.shelter_name, s.approval_status, "
            + "s.reviewed_at, s.reviewed_by, u.name as reviewer_name "
            + "FROM shelter s "
            + "LEFT JOIN users u ON s.reviewed_by = u.user_id "
            + "WHERE s.approval_status IN ('approved', 'rejected') "
            + "AND s.reviewed_at IS NOT NULL "
            + "ORDER BY s.reviewed_at DESC "
            + "FETCH FIRST ? ROWS ONLY";
    
    try (PreparedStatement stmt = connection.prepareStatement(sql)) {
        stmt.setInt(1, limit);
        
        try (ResultSet rs = stmt.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> activity = new HashMap<>();
                activity.put("shelterId", rs.getInt("shelter_id"));
                activity.put("shelterName", rs.getString("shelter_name"));
                activity.put("status", rs.getString("approval_status"));
                activity.put("reviewedAt", rs.getTimestamp("reviewed_at"));
                activity.put("reviewerName", rs.getString("reviewer_name"));
                
                activities.add(activity);
            }
        }
    }
    
    return activities;
}
}
