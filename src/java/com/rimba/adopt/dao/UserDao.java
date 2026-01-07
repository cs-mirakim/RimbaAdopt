package com.rimba.adopt.dao;

import com.rimba.adopt.model.Users;
import com.rimba.adopt.model.Admin;
import com.rimba.adopt.model.Adopter;
import com.rimba.adopt.model.Shelter;
import com.rimba.adopt.util.dbConnection;
import java.sql.*;
import java.util.logging.Level;
import java.util.logging.Logger;

public class UserDao {

    private static final Logger logger = Logger.getLogger(UserDao.class.getName());

    public Users authenticateUser(String email, String hashedPassword, String role) throws SQLException {
        String sql = "SELECT u.* FROM users u WHERE u.email = ? AND u.password = ? AND u.role = ?";

        try (Connection conn = dbConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, email);
            pstmt.setString(2, hashedPassword);
            pstmt.setString(3, role);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    Users user = new Users();
                    user.setUserId(rs.getInt("user_id"));
                    user.setName(rs.getString("name"));
                    user.setEmail(rs.getString("email"));
                    user.setPassword(rs.getString("password"));
                    user.setPhone(rs.getString("phone"));
                    user.setRole(rs.getString("role"));
                    user.setProfilePhotoPath(rs.getString("profile_photo_path"));
                    user.setCreatedAt(rs.getTimestamp("created_at"));

                    logger.log(Level.INFO, "User authenticated: {0} ({1})",
                            new Object[]{email, role});
                    return user;
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error authenticating user: " + email, e);
            throw e;
        }

        logger.log(Level.WARNING, "Authentication failed for: {0} ({1})",
                new Object[]{email, role});
        return null;
    }

    public Admin getAdminDetails(Integer userId) throws SQLException {
        String sql = "SELECT a.* FROM admin a WHERE a.admin_id = ?";

        try (Connection conn = dbConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    Admin admin = new Admin();
                    admin.setAdminId(rs.getInt("admin_id"));
                    admin.setPosition(rs.getString("position"));
                    return admin;
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting admin details for user: " + userId, e);
            throw e;
        }
        return null;
    }

    public Adopter getAdopterDetails(Integer userId) throws SQLException {
        String sql = "SELECT a.* FROM adopter a WHERE a.adopter_id = ?";

        try (Connection conn = dbConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    Adopter adopter = new Adopter();
                    adopter.setAdopterId(rs.getInt("adopter_id"));
                    adopter.setAddress(rs.getString("address"));
                    adopter.setOccupation(rs.getString("occupation"));
                    adopter.setHouseholdType(rs.getString("household_type"));

                    // Handle has_other_pets (SMALLINT to Integer)
                    Object hasOtherPetsObj = rs.getObject("has_other_pets");
                    if (hasOtherPetsObj != null) {
                        if (hasOtherPetsObj instanceof Number) {
                            adopter.setHasOtherPets(((Number) hasOtherPetsObj).intValue());
                        } else if (hasOtherPetsObj instanceof Boolean) {
                            adopter.setHasOtherPets(((Boolean) hasOtherPetsObj) ? 1 : 0);
                        }
                    }

                    adopter.setNotes(rs.getString("notes"));
                    return adopter;
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting adopter details for user: " + userId, e);
            throw e;
        }
        return null;
    }

    public Shelter getShelterDetails(Integer userId) throws SQLException {
        String sql = "SELECT s.* FROM shelter s WHERE s.shelter_id = ?";

        try (Connection conn = dbConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    Shelter shelter = new Shelter();
                    shelter.setShelterId(rs.getInt("shelter_id"));
                    shelter.setShelterName(rs.getString("shelter_name"));
                    shelter.setShelterAddress(rs.getString("shelter_address"));
                    shelter.setShelterDescription(rs.getString("shelter_description"));
                    shelter.setWebsite(rs.getString("website"));
                    shelter.setOperatingHours(rs.getString("operating_hours"));
                    shelter.setApprovalStatus(rs.getString("approval_status"));

                    // reviewed_by
                    Object reviewedByObj = rs.getObject("reviewed_by");
                    if (reviewedByObj != null) {
                        shelter.setReviewedBy(((Number) reviewedByObj).intValue());
                    }

                    shelter.setReviewedAt(rs.getTimestamp("reviewed_at"));
                    shelter.setApprovalMessage(rs.getString("approval_message"));
                    shelter.setRejectionReason(rs.getString("rejection_reason"));

                    // notification_sent
                    Object notificationSentObj = rs.getObject("notification_sent");
                    if (notificationSentObj != null) {
                        shelter.setNotificationSent(((Number) notificationSentObj).intValue());
                    }

                    shelter.setNotificationSentAt(rs.getTimestamp("notification_sent_at"));
                    return shelter;
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting shelter details for user: " + userId, e);
            throw e;
        }
        return null;
    }

    // Tambah method berikut dalam UserDao.java:
    public boolean updateUserProfile(Users user) throws SQLException {
        String sql = "UPDATE users SET name = ?, email = ?, phone = ?, profile_photo_path = ? WHERE user_id = ?";

        try (Connection conn = dbConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, user.getName());
            pstmt.setString(2, user.getEmail());
            pstmt.setString(3, user.getPhone());
            pstmt.setString(4, user.getProfilePhotoPath());
            pstmt.setInt(5, user.getUserId());

            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
        }
    }

    public boolean updateAdminProfile(Admin admin) throws SQLException {
        String sql = "UPDATE admin SET position = ? WHERE admin_id = ?";

        try (Connection conn = dbConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, admin.getPosition());
            pstmt.setInt(2, admin.getAdminId());

            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
        }
    }

    public boolean updateAdopterProfile(Adopter adopter) throws SQLException {
        String sql = "UPDATE adopter SET address = ?, occupation = ?, household_type = ?, "
                + "has_other_pets = ?, notes = ? WHERE adopter_id = ?";

        try (Connection conn = dbConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, adopter.getAddress());
            pstmt.setString(2, adopter.getOccupation());
            pstmt.setString(3, adopter.getHouseholdType());
            pstmt.setInt(4, adopter.getHasOtherPets());
            pstmt.setString(5, adopter.getNotes());
            pstmt.setInt(6, adopter.getAdopterId());

            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
        }
    }

    public boolean updateShelterProfile(Shelter shelter) throws SQLException {
        String sql = "UPDATE shelter SET shelter_name = ?, shelter_address = ?, shelter_description = ?, "
                + "website = ?, operating_hours = ? WHERE shelter_id = ?";

        try (Connection conn = dbConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, shelter.getShelterName());
            pstmt.setString(2, shelter.getShelterAddress());
            pstmt.setString(3, shelter.getShelterDescription());
            pstmt.setString(4, shelter.getWebsite());
            pstmt.setString(5, shelter.getOperatingHours());
            pstmt.setInt(6, shelter.getShelterId());

            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
        }
    }

    // Helper method to check if email exists
    public boolean checkEmailExists(String email) throws SQLException {
        String sql = "SELECT COUNT(*) FROM users WHERE email = ?";

        try (Connection conn = dbConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, email);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        }
        return false;
    }

    // Get user by email only (for forgot password functionality)
    public Users getUserByEmail(String email) throws SQLException {
        String sql = "SELECT * FROM users WHERE email = ?";

        try (Connection conn = dbConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, email);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    Users user = new Users();
                    user.setUserId(rs.getInt("user_id"));
                    user.setName(rs.getString("name"));
                    user.setEmail(rs.getString("email"));
                    user.setPassword(rs.getString("password"));
                    user.setPhone(rs.getString("phone"));
                    user.setRole(rs.getString("role"));
                    user.setProfilePhotoPath(rs.getString("profile_photo_path"));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                    return user;
                }
            }
        }
        return null;
    }

    // Dalam UserDao.java, tambah method berikut:
    public Users getUserById(Integer userId) throws SQLException {
        String sql = "SELECT * FROM users WHERE user_id = ?";

        try (Connection conn = dbConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, userId);

            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    Users user = new Users();
                    user.setUserId(rs.getInt("user_id"));
                    user.setName(rs.getString("name"));
                    user.setEmail(rs.getString("email"));
                    user.setPassword(rs.getString("password"));
                    user.setPhone(rs.getString("phone"));
                    user.setRole(rs.getString("role"));
                    user.setProfilePhotoPath(rs.getString("profile_photo_path"));
                    user.setCreatedAt(rs.getTimestamp("created_at"));
                    return user;
                }
            }
        }
        return null;
    }

    public boolean deleteUser(int userId) {
        Connection connection = null;
        PreparedStatement preparedStatement = null;

        try {
            connection = dbConnection.getConnection();

            // Mulakan transaction
            connection.setAutoCommit(false);

            // First, check user's role untuk tahu table mana yang perlu di-delete
            String role = getUserRoleById(userId, connection);
            if (role == null) {
                return false; // User tidak wujud
            }

            // Delete dari role-specific table berdasarkan role
            switch (role.toLowerCase()) {
                case "adopter":
                    String deleteAdopterQuery = "DELETE FROM adopter WHERE user_id = ?";
                    preparedStatement = connection.prepareStatement(deleteAdopterQuery);
                    preparedStatement.setInt(1, userId);
                    preparedStatement.executeUpdate();
                    break;

                case "shelter":
                    String deleteShelterQuery = "DELETE FROM shelter WHERE user_id = ?";
                    preparedStatement = connection.prepareStatement(deleteShelterQuery);
                    preparedStatement.setInt(1, userId);
                    preparedStatement.executeUpdate();
                    break;

                case "admin":
                    String deleteAdminQuery = "DELETE FROM admin WHERE user_id = ?";
                    preparedStatement = connection.prepareStatement(deleteAdminQuery);
                    preparedStatement.setInt(1, userId);
                    preparedStatement.executeUpdate();
                    break;
            }

            // Delete dari users table
            String deleteUserQuery = "DELETE FROM users WHERE user_id = ?";
            preparedStatement = connection.prepareStatement(deleteUserQuery);
            preparedStatement.setInt(1, userId);
            int rowsAffected = preparedStatement.executeUpdate();

            // Commit transaction
            connection.commit();

            return rowsAffected > 0;

        } catch (SQLException e) {
            if (connection != null) {
                try {
                    connection.rollback();
                } catch (SQLException ex) {
                    ex.printStackTrace();
                }
            }
            logger.log(Level.SEVERE, "Error deleting user: " + userId, e);
            return false;
        } finally {
            if (preparedStatement != null) {
                try {
                    preparedStatement.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
            if (connection != null) {
                try {
                    connection.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }

// Helper method untuk dapatkan role user
    private String getUserRoleById(Integer userId, Connection conn) throws SQLException {
        String sql = "SELECT role FROM users WHERE user_id = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("role");
                }
            }
        }
        return null;
    }

    private void deleteFromTable(String tableName, String idColumn, Integer userId, Connection conn)
            throws SQLException {
        String sql = "DELETE FROM " + tableName + " WHERE " + idColumn + " = ?";
        try (PreparedStatement pstmt = conn.prepareStatement(sql)) {
            pstmt.setInt(1, userId);
            pstmt.executeUpdate();
        }
    }
}
