package com.rimba.adopt.dao;

import com.rimba.adopt.model.LostReport;
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class LostReportDAO {

    // Create a new lost report
    public int createLostReport(LostReport lostReport) throws SQLException {
        String sql = "INSERT INTO lost_report (adopter_id, pet_name, species, last_seen_location, " +
                     "last_seen_date, description, photo_path, status) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            
            pstmt.setInt(1, lostReport.getAdopterId());
            pstmt.setString(2, lostReport.getPetName());
            pstmt.setString(3, lostReport.getSpecies());
            pstmt.setString(4, lostReport.getLastSeenLocation());
            
            if (lostReport.getLastSeenDate() != null) {
                pstmt.setDate(5, lostReport.getLastSeenDate());
            } else {
                pstmt.setDate(5, new Date(System.currentTimeMillis()));
            }
            
            pstmt.setString(6, lostReport.getDescription());
            pstmt.setString(7, lostReport.getPhotoPath());
            pstmt.setString(8, lostReport.getStatus() != null ? lostReport.getStatus() : "lost");
            
            int affectedRows = pstmt.executeUpdate();
            
            if (affectedRows > 0) {
                try (ResultSet generatedKeys = pstmt.getGeneratedKeys()) {
                    if (generatedKeys.next()) {
                        return generatedKeys.getInt(1);
                    }
                }
            }
            return -1;
        }
    }

    // Get all lost reports with adopter info (return as Map)
    public List<Map<String, Object>> getAllLostReportsWithAdopter() throws SQLException {
        List<Map<String, Object>> reports = new ArrayList<>();
        String sql = "SELECT lr.*, u.name as adopter_name, u.email as adopter_email, u.phone as adopter_phone " +
                     "FROM lost_report lr " +
                     "INNER JOIN adopter a ON lr.adopter_id = a.adopter_id " +
                     "INNER JOIN users u ON a.adopter_id = u.user_id " +
                     "ORDER BY lr.created_at DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql);
             ResultSet rs = pstmt.executeQuery()) {
            
            while (rs.next()) {
                Map<String, Object> report = extractLostReportWithAdopterFromResultSet(rs);
                reports.add(report);
            }
        }
        return reports;
    }

    // Get lost report by ID with adopter info
    public Map<String, Object> getLostReportWithAdopterById(int lostId) throws SQLException {
        String sql = "SELECT lr.*, u.name as adopter_name, u.email as adopter_email, u.phone as adopter_phone " +
                     "FROM lost_report lr " +
                     "INNER JOIN adopter a ON lr.adopter_id = a.adopter_id " +
                     "INNER JOIN users u ON a.adopter_id = u.user_id " +
                     "WHERE lr.lost_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, lostId);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return extractLostReportWithAdopterFromResultSet(rs);
                }
            }
        }
        return null;
    }

    // Get lost reports by adopter ID
    public List<LostReport> getLostReportsByAdopter(int adopterId) throws SQLException {
        List<LostReport> lostReports = new ArrayList<>();
        String sql = "SELECT * FROM lost_report WHERE adopter_id = ? ORDER BY created_at DESC";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, adopterId);
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    LostReport report = extractLostReportFromResultSet(rs);
                    lostReports.add(report);
                }
            }
        }
        return lostReports;
    }

    // Update lost report status
    public boolean updateLostReportStatus(int lostId, String status) throws SQLException {
        String sql = "UPDATE lost_report SET status = ? WHERE lost_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, status);
            pstmt.setInt(2, lostId);
            
            return pstmt.executeUpdate() > 0;
        }
    }

    // Update lost report
    public boolean updateLostReport(LostReport lostReport) throws SQLException {
        String sql = "UPDATE lost_report SET pet_name = ?, species = ?, last_seen_location = ?, " +
                     "last_seen_date = ?, description = ?, photo_path = ?, status = ? " +
                     "WHERE lost_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, lostReport.getPetName());
            pstmt.setString(2, lostReport.getSpecies());
            pstmt.setString(3, lostReport.getLastSeenLocation());
            pstmt.setDate(4, lostReport.getLastSeenDate());
            pstmt.setString(5, lostReport.getDescription());
            pstmt.setString(6, lostReport.getPhotoPath());
            pstmt.setString(7, lostReport.getStatus());
            pstmt.setInt(8, lostReport.getLostId());
            
            return pstmt.executeUpdate() > 0;
        }
    }

    // Delete lost report
    public boolean deleteLostReport(int lostId) throws SQLException {
        String sql = "DELETE FROM lost_report WHERE lost_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, lostId);
            return pstmt.executeUpdate() > 0;
        }
    }

    // Search lost reports with filters
    public List<Map<String, Object>> searchLostReportsWithAdopter(String status, String species, String location, Integer daysAgo) throws SQLException {
        List<Map<String, Object>> reports = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
            "SELECT lr.*, u.name as adopter_name, u.email as adopter_email, u.phone as adopter_phone " +
            "FROM lost_report lr " +
            "INNER JOIN adopter a ON lr.adopter_id = a.adopter_id " +
            "INNER JOIN users u ON a.adopter_id = u.user_id " +
            "WHERE 1=1"
        );
        
        List<Object> params = new ArrayList<>();
        
        if (status != null && !status.isEmpty()) {
            sql.append(" AND lr.status = ?");
            params.add(status);
        }
        
        if (species != null && !species.isEmpty()) {
            sql.append(" AND lr.species = ?");
            params.add(species);
        }
        
        if (location != null && !location.isEmpty()) {
            sql.append(" AND LOWER(lr.last_seen_location) LIKE ?");
            params.add("%" + location.toLowerCase() + "%");
        }
        
        if (daysAgo != null && daysAgo > 0) {
            sql.append(" AND lr.last_seen_date >= ?");
            Date dateFilter = new Date(System.currentTimeMillis() - (daysAgo * 24L * 60 * 60 * 1000));
            params.add(dateFilter);
        }
        
        sql.append(" ORDER BY lr.created_at DESC");
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                pstmt.setObject(i + 1, params.get(i));
            }
            
            try (ResultSet rs = pstmt.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> report = extractLostReportWithAdopterFromResultSet(rs);
                    reports.add(report);
                }
            }
        }
        return reports;
    }

    // Count lost reports by status
    public int countLostReportsByStatus(String status) throws SQLException {
        String sql = "SELECT COUNT(*) FROM lost_report WHERE status = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setString(1, status);
            try (ResultSet rs = pstmt.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        }
        return 0;
    }

    // Helper method to extract LostReport from ResultSet (without adopter info)
    private LostReport extractLostReportFromResultSet(ResultSet rs) throws SQLException {
        LostReport report = new LostReport();
        
        report.setLostId(rs.getInt("lost_id"));
        report.setAdopterId(rs.getInt("adopter_id"));
        report.setPetName(rs.getString("pet_name"));
        report.setSpecies(rs.getString("species"));
        report.setLastSeenLocation(rs.getString("last_seen_location"));
        report.setLastSeenDate(rs.getDate("last_seen_date"));
        report.setDescription(rs.getString("description"));
        report.setPhotoPath(rs.getString("photo_path"));
        report.setStatus(rs.getString("status"));
        report.setCreatedAt(rs.getTimestamp("created_at"));
        
        return report;
    }

    // Helper method to extract LostReport with adopter info as Map
    private Map<String, Object> extractLostReportWithAdopterFromResultSet(ResultSet rs) throws SQLException {
        Map<String, Object> report = new HashMap<>();
        
        // Lost report data
        report.put("lost_id", rs.getInt("lost_id"));
        report.put("adopter_id", rs.getInt("adopter_id"));
        report.put("pet_name", rs.getString("pet_name"));
        report.put("species", rs.getString("species"));
        report.put("last_seen_location", rs.getString("last_seen_location"));
        report.put("last_seen_date", rs.getDate("last_seen_date"));
        report.put("description", rs.getString("description"));
        report.put("photo_path", rs.getString("photo_path"));
        report.put("status", rs.getString("status"));
        report.put("created_at", rs.getTimestamp("created_at"));
        
        // Adopter information
        report.put("adopter_name", rs.getString("adopter_name"));
        report.put("adopter_email", rs.getString("adopter_email"));
        report.put("adopter_phone", rs.getString("adopter_phone"));
        
        return report;
    }
    
    // NEW METHOD: Get lost report statistics for adopter
public Map<String, Integer> getLostReportStatsByAdopter(int adopterId) throws SQLException {
    Map<String, Integer> stats = new HashMap<>();
    
    String query = "SELECT status, COUNT(*) as count " +
                   "FROM lost_report " +
                   "WHERE adopter_id = ? " +
                   "GROUP BY status";
    
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement pstmt = conn.prepareStatement(query)) {
        
        pstmt.setInt(1, adopterId);
        try (ResultSet rs = pstmt.executeQuery()) {
            while (rs.next()) {
                String status = rs.getString("status");
                int count = rs.getInt("count");
                stats.put(status.toLowerCase(), count);
            }
        }
    }
    
    // Calculate total
    int total = stats.values().stream().mapToInt(Integer::intValue).sum();
    stats.put("total", total);
    
    return stats;
}

// NEW METHOD: Get monthly lost report stats for adopter
public Map<String, List<Integer>> getMonthlyLostStatsByAdopter(int adopterId) throws SQLException {
    Map<String, List<Integer>> monthlyStats = new HashMap<>();
    
    // Initialize arrays for each status (12 months)
    List<Integer> monthlyLost = new ArrayList<>(Collections.nCopies(12, 0));
    List<Integer> monthlyFound = new ArrayList<>(Collections.nCopies(12, 0));
    
    String query = "SELECT MONTH(created_at) as month, status, COUNT(*) as count " +
                   "FROM lost_report " +
                   "WHERE adopter_id = ? AND YEAR(created_at) = YEAR(CURDATE()) " +
                   "GROUP BY MONTH(created_at), status " +
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
                    if (status.equalsIgnoreCase("lost")) {
                        monthlyLost.set(month, count);
                    } else if (status.equalsIgnoreCase("found")) {
                        monthlyFound.set(month, count);
                    }
                }
            }
        }
    }
    
    monthlyStats.put("lost", monthlyLost);
    monthlyStats.put("found", monthlyFound);
    
    return monthlyStats;
}
}