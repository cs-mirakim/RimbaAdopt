package com.rimba.adopt.dao;

import com.rimba.adopt.model.AdoptionRecord;
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.Date;

public class AdoptionRecordDAO {
    
    // Create adoption record when request is approved
    public boolean createRecord(AdoptionRecord record) throws SQLException {
        String sql = "INSERT INTO adoption_record (request_id, adopter_id, pet_id, adoption_date, remarks) " +
                     "VALUES (?, ?, ?, ?, ?)";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, record.getRequestId());
            pstmt.setInt(2, record.getAdopterId());
            pstmt.setInt(3, record.getPetId());
            pstmt.setDate(4, record.getAdoptionDate());
            pstmt.setString(5, record.getRemarks());
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
        }
    }
    
    // Check if record already exists for a request
    public boolean recordExists(int requestId) throws SQLException {
        String sql = "SELECT COUNT(*) as count FROM adoption_record WHERE request_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, requestId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt("count") > 0;
            }
        }
        return false;
    }
    
    // Get adoption record by request ID
    public AdoptionRecord getRecordByRequestId(int requestId) throws SQLException {
        String sql = "SELECT * FROM adoption_record WHERE request_id = ?";
        
        try (Connection conn = DatabaseConnection.getConnection();
             PreparedStatement pstmt = conn.prepareStatement(sql)) {
            
            pstmt.setInt(1, requestId);
            ResultSet rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return extractAdoptionRecord(rs);
            }
        }
        return null;
    }
    
    // Helper method to extract AdoptionRecord from ResultSet
    private AdoptionRecord extractAdoptionRecord(ResultSet rs) throws SQLException {
        AdoptionRecord record = new AdoptionRecord();
        
        record.setRecordId(rs.getInt("record_id"));
        record.setRequestId(rs.getInt("request_id"));
        record.setAdopterId(rs.getInt("adopter_id"));
        record.setPetId(rs.getInt("pet_id"));
        record.setAdoptionDate(rs.getDate("adoption_date"));
        record.setRemarks(rs.getString("remarks"));
        
        return record;
    }
}