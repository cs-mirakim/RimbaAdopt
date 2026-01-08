package com.rimba.adopt.dao;

import com.rimba.adopt.model.Users;
import com.rimba.adopt.model.Shelter;
import com.rimba.adopt.model.Adopter;
import java.sql.*;
import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

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

        } else if ("admin".equals(role)) {
            String sql = "SELECT * FROM admin WHERE admin_id = ?";
            try (PreparedStatement stmt = connection.prepareStatement(sql)) {
                stmt.setInt(1, userId);
                try (ResultSet rs = stmt.executeQuery()) {
                    if (rs.next()) {
                        Map<String, String> adminInfo = new HashMap<>();
                        adminInfo.put("position", rs.getString("position"));
                        profileData.put("admin", adminInfo);
                    }
                }
            }
        }

        return profileData;
    }

// ========== UPDATE USER ==========
    public boolean updateUser(Users user) throws SQLException {
        String sql = "UPDATE users SET name = ?, email = ?, phone = ?, profile_photo_path = ? WHERE user_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            stmt.setString(1, user.getName());
            stmt.setString(2, user.getEmail());
            stmt.setString(3, user.getPhone());

            if (user.getProfilePhotoPath() != null && !user.getProfilePhotoPath().isEmpty()) {
                stmt.setString(4, user.getProfilePhotoPath());
            } else {
                stmt.setNull(4, Types.VARCHAR);
            }

            stmt.setInt(5, user.getUserId());

            int rowsUpdated = stmt.executeUpdate();
            logger.info("Updated user ID " + user.getUserId() + ", Rows: " + rowsUpdated);
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
    public boolean updateAdmin(String position, int userId) throws SQLException {
        String sql = "UPDATE admin SET position = ? WHERE admin_id = ?";

        try (PreparedStatement stmt = connection.prepareStatement(sql)) {
            if (position != null && !position.isEmpty()) {
                stmt.setString(1, position);
            } else {
                stmt.setNull(1, Types.VARCHAR);
            }

            stmt.setInt(2, userId);

            int rowsUpdated = stmt.executeUpdate();
            logger.info("Updated admin for user ID " + userId + ", Rows: " + rowsUpdated);
            return rowsUpdated > 0;
        }
    }

// ========== DELETE USER (HARD DELETE CASCADE) ==========
    public boolean deleteUser(int userId) throws SQLException {
        // Note: shelter table ada ON DELETE CASCADE, so shelter akan delete automatik
        // Need manual delete untuk admin table

        // 1. Dapatkan role user untuk tahu file path
        String role = null;
        String profilePhotoPath = null;

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

        // 2. Delete dari users table (akan cascade ke shelter table)
        String deleteSql = "DELETE FROM users WHERE user_id = ?";
        try (PreparedStatement stmt = connection.prepareStatement(deleteSql)) {
            stmt.setInt(1, userId);
            int rowsDeleted = stmt.executeUpdate();
            logger.info("Deleted user ID " + userId + ", Rows: " + rowsDeleted);

            // Return info untuk delete file
            Map<String, String> result = new HashMap<>();
            result.put("role", role);
            result.put("profilePhotoPath", profilePhotoPath);
            result.put("success", rowsDeleted > 0 ? "true" : "false");

            return rowsDeleted > 0;
        }
    }

// ========== UPDATE PASSWORD ==========
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

}
