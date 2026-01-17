package com.rimba.adopt.dao;

import com.rimba.adopt.model.AwarenessBanner;
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

public class BannerDao {

    private static final Logger logger = Logger.getLogger(BannerDao.class.getName());

    public BannerDao() {
        // Check and add new columns if they don't exist
        checkAndUpdateTableSchema();
    }

    private void checkAndUpdateTableSchema() {
        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            DatabaseMetaData meta = conn.getMetaData();

            // Check if new columns exist
            ResultSet columns = meta.getColumns(null, null, "AWARENESS_BANNER", null);
            List<String> existingColumns = new ArrayList<>();
            while (columns.next()) {
                existingColumns.add(columns.getString("COLUMN_NAME").toLowerCase());
            }

            // Add missing columns
            try (Statement stmt = conn.createStatement()) {
                if (!existingColumns.contains("file_name")) {
                    stmt.executeUpdate("ALTER TABLE awareness_banner ADD file_name VARCHAR(255)");
                    logger.info("Added column: file_name");
                }
                if (!existingColumns.contains("file_size")) {
                    stmt.executeUpdate("ALTER TABLE awareness_banner ADD file_size INTEGER");
                    logger.info("Added column: file_size");
                }
                if (!existingColumns.contains("display_order")) {
                    stmt.executeUpdate("ALTER TABLE awareness_banner ADD display_order INTEGER DEFAULT 0");
                    logger.info("Added column: display_order");
                }
                if (!existingColumns.contains("caption")) {
                    stmt.executeUpdate("ALTER TABLE awareness_banner ADD caption VARCHAR(500)");
                    logger.info("Added column: caption");
                }
                if (!existingColumns.contains("image_dimensions")) {
                    stmt.executeUpdate("ALTER TABLE awareness_banner ADD image_dimensions VARCHAR(50)");
                    logger.info("Added column: image_dimensions");
                }
            }

        } catch (SQLException e) {
            logger.log(Level.WARNING, "Error checking/updating table schema", e);
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException e) {
                    logger.log(Level.WARNING, "Error closing connection", e);
                }
            }
        }
    }

    public List<Map<String, Object>> getAllBannersWithDetails() {
        List<Map<String, Object>> banners = new ArrayList<>();
        String sql = "SELECT * FROM awareness_banner ORDER BY COALESCE(display_order, 999) ASC, created_at DESC";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            rs = pstmt.executeQuery();

            logger.info("=== DAO: Executing query ===");
            logger.info("SQL: " + sql);

            int count = 0;
            while (rs.next()) {
                count++;
                Map<String, Object> banner = new HashMap<>();

                Integer bannerId = rs.getInt("banner_id");
                String title = rs.getString("title");
                String description = rs.getString("description");
                String imagePath = rs.getString("image_path");
                String status = rs.getString("status");
                Timestamp createdAt = rs.getTimestamp("created_at");

                banner.put("bannerId", bannerId);
                banner.put("title", title != null ? title : "");
                banner.put("description", description != null ? description : "");
                banner.put("imagePath", imagePath != null ? imagePath : "");
                banner.put("status", status != null ? status : "hidden");
                banner.put("createdAt", createdAt);

                Integer createdBy = rs.getInt("created_by");
                if (!rs.wasNull()) {
                    banner.put("createdBy", createdBy);
                } else {
                    banner.put("createdBy", null);
                }

                // Extended fields with null checks
                String fileName = rs.getString("file_name");
                banner.put("fileName", fileName != null ? fileName : "unknown.jpg");

                Long fileSize = rs.getLong("file_size");
                if (rs.wasNull()) {
                    banner.put("fileSize", 0L);
                } else {
                    banner.put("fileSize", fileSize);
                }

                int displayOrder = rs.getInt("display_order");
                if (rs.wasNull()) {
                    banner.put("displayOrder", 999);
                } else {
                    banner.put("displayOrder", displayOrder);
                }

                String caption = rs.getString("caption");
                banner.put("caption", caption != null ? caption : "");

                String imageDimensions = rs.getString("image_dimensions");
                banner.put("imageDimensions", imageDimensions != null ? imageDimensions : "1920x400");

                logger.info("Banner " + count + ": ID=" + bannerId + ", Title=" + title + ", Path=" + imagePath);

                banners.add(banner);
            }

            logger.info("Total banners fetched: " + count);

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting all banners with details", e);
            e.printStackTrace(); // ADD THIS for detailed error
        } finally {
            // IMPORTANT: Close resources in reverse order
            if (rs != null) {
                try {
                    rs.close();
                } catch (SQLException e) {
                    logger.log(Level.WARNING, "Error closing ResultSet", e);
                }
            }
            if (pstmt != null) {
                try {
                    pstmt.close();
                } catch (SQLException e) {
                    logger.log(Level.WARNING, "Error closing PreparedStatement", e);
                }
            }
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException e) {
                    logger.log(Level.WARNING, "Error closing connection", e);
                }
            }
        }

        return banners;
    }

    public List<AwarenessBanner> getActiveBanners() {
        List<AwarenessBanner> banners = new ArrayList<>();
        String sql = "SELECT * FROM awareness_banner WHERE status = 'visible' ORDER BY COALESCE(display_order, 999) ASC";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql);
                ResultSet rs = pstmt.executeQuery()) {

            while (rs.next()) {
                AwarenessBanner banner = mapResultSetToAwarenessBanner(rs);
                banners.add(banner);
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting active banners", e);
        }

        return banners;
    }

    public Map<String, Object> getBannerByIdWithDetails(int bannerId) {
        Map<String, Object> banner = null;
        String sql = "SELECT * FROM awareness_banner WHERE banner_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, bannerId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    banner = new HashMap<>();
                    banner.put("bannerId", rs.getInt("banner_id"));
                    banner.put("title", rs.getString("title"));
                    banner.put("description", rs.getString("description"));
                    banner.put("imagePath", rs.getString("image_path"));
                    banner.put("status", rs.getString("status"));
                    banner.put("createdAt", rs.getTimestamp("created_at"));

                    Integer createdBy = rs.getInt("created_by");
                    if (!rs.wasNull()) {
                        banner.put("createdBy", createdBy);
                    } else {
                        banner.put("createdBy", null);
                    }

                    // Extended fields
                    banner.put("fileName", rs.getString("file_name"));
                    banner.put("fileSize", rs.getLong("file_size"));

                    int displayOrder = rs.getInt("display_order");
                    if (rs.wasNull()) {
                        banner.put("displayOrder", 999);
                    } else {
                        banner.put("displayOrder", displayOrder);
                    }

                    banner.put("caption", rs.getString("caption"));
                    banner.put("imageDimensions", rs.getString("image_dimensions"));
                }
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting banner by ID", e);
        }

        return banner;
    }

    public int addBanner(Map<String, Object> bannerData) {
        String sql = "INSERT INTO awareness_banner (title, description, image_path, file_name, "
                + "file_size, display_order, caption, image_dimensions, status, created_by, created_at) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        int generatedId = -1;

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            pstmt.setString(1, (String) bannerData.get("title"));
            pstmt.setString(2, (String) bannerData.get("description"));
            pstmt.setString(3, (String) bannerData.get("imagePath"));
            pstmt.setString(4, (String) bannerData.get("fileName"));
            pstmt.setLong(5, (Long) bannerData.get("fileSize"));
            pstmt.setInt(6, (Integer) bannerData.get("displayOrder"));
            pstmt.setString(7, (String) bannerData.get("caption"));
            pstmt.setString(8, (String) bannerData.get("imageDimensions"));
            pstmt.setString(9, (String) bannerData.get("status"));

            Integer createdBy = (Integer) bannerData.get("createdBy");
            if (createdBy != null && createdBy > 0) {
                pstmt.setInt(10, createdBy);
            } else {
                pstmt.setNull(10, Types.INTEGER);
            }

            Timestamp createdAt = (Timestamp) bannerData.get("createdAt");
            if (createdAt != null) {
                pstmt.setTimestamp(11, createdAt);
            } else {
                pstmt.setTimestamp(11, new Timestamp(System.currentTimeMillis()));
            }

            int affectedRows = pstmt.executeUpdate();

            if (affectedRows > 0) {
                try (ResultSet rs = pstmt.getGeneratedKeys()) {
                    if (rs.next()) {
                        generatedId = rs.getInt(1);
                        logger.info("Banner added with ID: " + generatedId);
                    }
                }
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error adding banner", e);
        }

        return generatedId;
    }

    public boolean updateBannerCaption(int bannerId, String caption) {
        String sql = "UPDATE awareness_banner SET caption = ? WHERE banner_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, caption);
            pstmt.setInt(2, bannerId);

            int affectedRows = pstmt.executeUpdate();
            logger.info("Updated caption for banner ID " + bannerId + ", Rows affected: " + affectedRows);
            return affectedRows > 0;

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error updating banner caption", e);
            return false;
        }
    }

    public boolean updateBannerStatus(int bannerId, String status) {
        String sql = "UPDATE awareness_banner SET status = ? WHERE banner_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setString(1, status);
            pstmt.setInt(2, bannerId);

            int affectedRows = pstmt.executeUpdate();
            logger.info("Updated status for banner ID " + bannerId + " to " + status + ", Rows affected: " + affectedRows);
            return affectedRows > 0;

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error updating banner status", e);
            return false;
        }
    }

    public boolean updateBannerOrder(int bannerId, int displayOrder) {
        String sql = "UPDATE awareness_banner SET display_order = ? WHERE banner_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, displayOrder);
            pstmt.setInt(2, bannerId);

            int affectedRows = pstmt.executeUpdate();
            logger.info("Updated order for banner ID " + bannerId + " to " + displayOrder + ", Rows affected: " + affectedRows);
            return affectedRows > 0;

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error updating banner order", e);
            return false;
        }
    }

    public boolean updateAllBannerOrders(List<Integer> bannerIds) {
        Connection conn = null;
        try {
            conn = DatabaseConnection.getConnection();
            conn.setAutoCommit(false);

            // First reset all orders to 0
            String resetSql = "UPDATE awareness_banner SET display_order = 0";
            try (PreparedStatement resetStmt = conn.prepareStatement(resetSql)) {
                resetStmt.executeUpdate();
            }

            // Then set new orders
            String updateSql = "UPDATE awareness_banner SET display_order = ? WHERE banner_id = ?";
            try (PreparedStatement updateStmt = conn.prepareStatement(updateSql)) {
                for (int i = 0; i < bannerIds.size(); i++) {
                    updateStmt.setInt(1, i + 1); // Start from 1
                    updateStmt.setInt(2, bannerIds.get(i));
                    updateStmt.addBatch();
                }

                int[] results = updateStmt.executeBatch();
                conn.commit();

                // Check if all updates were successful
                for (int result : results) {
                    if (result <= 0) {
                        logger.warning("Failed to update order for some banners");
                        return false;
                    }
                }
                logger.info("Updated orders for " + bannerIds.size() + " banners");
                return true;
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error updating all banner orders", e);
            if (conn != null) {
                try {
                    conn.rollback();
                } catch (SQLException ex) {
                    logger.log(Level.WARNING, "Error during rollback", ex);
                }
            }
            return false;
        } finally {
            if (conn != null) {
                try {
                    conn.close();
                } catch (SQLException e) {
                    logger.log(Level.WARNING, "Error closing connection", e);
                }
            }
        }
    }

    public boolean deleteBanner(int bannerId) {
        String sql = "DELETE FROM awareness_banner WHERE banner_id = ?";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql)) {

            pstmt.setInt(1, bannerId);

            int affectedRows = pstmt.executeUpdate();
            logger.info("Deleted banner ID " + bannerId + ", Rows affected: " + affectedRows);
            return affectedRows > 0;

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error deleting banner", e);
            return false;
        }
    }

    public int getNextDisplayOrder() {
        String sql = "SELECT COALESCE(MAX(display_order), 0) + 1 AS next_order FROM awareness_banner";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql);
                ResultSet rs = pstmt.executeQuery()) {

            if (rs.next()) {
                return rs.getInt("next_order");
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting next display order", e);
        }

        return 1; // Default to 1 if error
    }

    public long getTotalStorageUsed() {
        String sql = "SELECT COALESCE(SUM(file_size), 0) AS total_size FROM awareness_banner";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql);
                ResultSet rs = pstmt.executeQuery()) {

            if (rs.next()) {
                long total = rs.getLong("total_size");
                logger.info("Total storage used: " + total + " bytes");
                return total;
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting total storage used", e);
        }

        return 0;
    }

    public int getActiveBannerCount() {
        String sql = "SELECT COUNT(*) AS count FROM awareness_banner WHERE status = 'visible'";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql);
                ResultSet rs = pstmt.executeQuery()) {

            if (rs.next()) {
                int count = rs.getInt("count");
                logger.info("Active banner count: " + count);
                return count;
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting active banner count", e);
        }

        return 0;
    }

    public int getTotalBannerCount() {
        String sql = "SELECT COUNT(*) AS count FROM awareness_banner";

        try (Connection conn = DatabaseConnection.getConnection();
                PreparedStatement pstmt = conn.prepareStatement(sql);
                ResultSet rs = pstmt.executeQuery()) {

            if (rs.next()) {
                int count = rs.getInt("count");
                logger.info("Total banner count: " + count);
                return count;
            }

        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting total banner count", e);
        }

        return 0;
    }

    private AwarenessBanner mapResultSetToAwarenessBanner(ResultSet rs) throws SQLException {
        AwarenessBanner banner = new AwarenessBanner();
        banner.setBannerId(rs.getInt("banner_id"));
        banner.setTitle(rs.getString("title"));
        banner.setDescription(rs.getString("description"));
        banner.setImagePath(rs.getString("image_path"));
        banner.setStatus(rs.getString("status"));
        banner.setCreatedAt(rs.getTimestamp("created_at"));

        int createdBy = rs.getInt("created_by");
        if (!rs.wasNull()) {
            banner.setCreatedBy(createdBy);
        }

        return banner;
    }
}
