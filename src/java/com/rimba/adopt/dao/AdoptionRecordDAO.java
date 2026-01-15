package com.rimba.adopt.dao;

import com.rimba.adopt.model.AdoptionRecord;
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.logging.Level;
import java.util.logging.Logger;

public class AdoptionRecordDAO {

    private static final Logger logger = Logger.getLogger(AdoptionRecordDAO.class.getName());

    // Create adoption record setelah request approved
    public boolean createRecord(AdoptionRecord record) throws SQLException {
        String query
                = "INSERT INTO adoption_record (request_id, adopter_id, pet_id, adoption_date, remarks) "
                + "VALUES (?, ?, ?, ?, ?)";

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query);

            pstmt.setInt(1, record.getRequestId());
            pstmt.setInt(2, record.getAdopterId());
            pstmt.setInt(3, record.getPetId());
            pstmt.setDate(4, record.getAdoptionDate());

            if (record.getRemarks() != null && !record.getRemarks().isEmpty()) {
                pstmt.setString(5, record.getRemarks());
            } else {
                pstmt.setNull(5, Types.CLOB);
            }

            int rowsInserted = pstmt.executeUpdate();

            logger.log(Level.INFO, "Created adoption record for request {0}", record.getRequestId());

            return rowsInserted > 0;

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

    // Check if pet already has an adoption record (already adopted)
    public boolean isPetAlreadyAdopted(int petId) throws SQLException {
        String query
                = "SELECT COUNT(*) FROM adoption_record WHERE pet_id = ?";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, petId);

            rs = pstmt.executeQuery();

            if (rs.next()) {
                return rs.getInt(1) > 0;
            }

            return false;

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

    // Get adoption record by request ID
    public AdoptionRecord getRecordByRequestId(int requestId) throws SQLException {
        String query = "SELECT * FROM adoption_record WHERE request_id = ?";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(query);
            pstmt.setInt(1, requestId);

            rs = pstmt.executeQuery();

            if (rs.next()) {
                AdoptionRecord record = new AdoptionRecord();
                record.setRecordId(rs.getInt("record_id"));
                record.setRequestId(rs.getInt("request_id"));
                record.setAdopterId(rs.getInt("adopter_id"));
                record.setPetId(rs.getInt("pet_id"));
                record.setAdoptionDate(rs.getDate("adoption_date"));
                record.setRemarks(rs.getString("remarks"));

                return record;
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
}
