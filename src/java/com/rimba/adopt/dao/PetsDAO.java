package com.rimba.adopt.dao;

import com.rimba.adopt.model.Pets;
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PetsDAO {
    
    // Create a new pet
    public int createPet(Pets pet) throws SQLException {
        String sql = "INSERT INTO pets (shelter_id, name, species, breed, age, gender, size, color, description, health_status, photo_path) " +
                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
            
            pstmt.setInt(1, pet.getShelterId());
            pstmt.setString(2, pet.getName());
            pstmt.setString(3, pet.getSpecies());
            
            if (pet.getBreed() != null && !pet.getBreed().isEmpty()) {
                pstmt.setString(4, pet.getBreed());
            } else {
                pstmt.setNull(4, Types.VARCHAR);
            }
            
            if (pet.getAge() != null) {
                pstmt.setInt(5, pet.getAge());
            } else {
                pstmt.setNull(5, Types.INTEGER);
            }
            
            pstmt.setString(6, pet.getGender());
            pstmt.setString(7, pet.getSize());
            
            if (pet.getColor() != null && !pet.getColor().isEmpty()) {
                pstmt.setString(8, pet.getColor());
            } else {
                pstmt.setNull(8, Types.VARCHAR);
            }
            
            if (pet.getDescription() != null && !pet.getDescription().isEmpty()) {
                pstmt.setString(9, pet.getDescription());
            } else {
                pstmt.setNull(9, Types.CLOB);
            }
            
            if (pet.getHealthStatus() != null && !pet.getHealthStatus().isEmpty()) {
                pstmt.setString(10, pet.getHealthStatus());
            } else {
                pstmt.setNull(10, Types.VARCHAR);
            }
            
            if (pet.getPhotoPath() != null && !pet.getPhotoPath().isEmpty()) {
                pstmt.setString(11, pet.getPhotoPath());
            } else {
                pstmt.setNull(11, Types.VARCHAR);
            }
            
            int affectedRows = pstmt.executeUpdate();
            
            if (affectedRows > 0) {
                rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    int generatedId = rs.getInt(1);
                    pet.setPetId(generatedId);
                    return generatedId;
                }
            }
            
            return -1; // Insert failed
            
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }
    
    // Get all pets for a specific shelter
    public List<Pets> getPetsByShelter(int shelterId) throws SQLException {
        List<Pets> pets = new ArrayList<>();
        String sql = "SELECT * FROM pets WHERE shelter_id = ? ORDER BY created_at DESC";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Pets pet = resultSetToPet(rs);
                pets.add(pet);
            }
            
            return pets;
            
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }
    
    // Get pet by ID
    public Pets getPetById(int petId) throws SQLException {
        String sql = "SELECT * FROM pets WHERE pet_id = ?";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, petId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return resultSetToPet(rs);
            }
            
            return null;
            
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }
    
    // Get pet by ID with shelter verification
    public Pets getPetByIdAndShelter(int petId, int shelterId) throws SQLException {
        String sql = "SELECT * FROM pets WHERE pet_id = ? AND shelter_id = ?";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, petId);
            pstmt.setInt(2, shelterId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return resultSetToPet(rs);
            }
            
            return null;
            
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }
    
    // Update pet
    public boolean updatePet(Pets pet) throws SQLException {
        String sql = "UPDATE pets SET name = ?, species = ?, breed = ?, age = ?, gender = ?, " +
                     "size = ?, color = ?, description = ?, health_status = ?, photo_path = ? " +
                     "WHERE pet_id = ? AND shelter_id = ?";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            
            pstmt.setString(1, pet.getName());
            pstmt.setString(2, pet.getSpecies());
            
            if (pet.getBreed() != null && !pet.getBreed().isEmpty()) {
                pstmt.setString(3, pet.getBreed());
            } else {
                pstmt.setNull(3, Types.VARCHAR);
            }
            
            if (pet.getAge() != null) {
                pstmt.setInt(4, pet.getAge());
            } else {
                pstmt.setNull(4, Types.INTEGER);
            }
            
            pstmt.setString(5, pet.getGender());
            pstmt.setString(6, pet.getSize());
            
            if (pet.getColor() != null && !pet.getColor().isEmpty()) {
                pstmt.setString(7, pet.getColor());
            } else {
                pstmt.setNull(7, Types.VARCHAR);
            }
            
            if (pet.getDescription() != null && !pet.getDescription().isEmpty()) {
                pstmt.setString(8, pet.getDescription());
            } else {
                pstmt.setNull(8, Types.CLOB);
            }
            
            if (pet.getHealthStatus() != null && !pet.getHealthStatus().isEmpty()) {
                pstmt.setString(9, pet.getHealthStatus());
            } else {
                pstmt.setNull(9, Types.VARCHAR);
            }
            
            if (pet.getPhotoPath() != null && !pet.getPhotoPath().isEmpty()) {
                pstmt.setString(10, pet.getPhotoPath());
            } else {
                pstmt.setNull(10, Types.VARCHAR);
            }
            
            pstmt.setInt(11, pet.getPetId());
            pstmt.setInt(12, pet.getShelterId());
            
            int affectedRows = pstmt.executeUpdate();
            return affectedRows > 0;
            
        } finally {
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }
    
    // Delete pet
    public boolean deletePet(int petId, int shelterId) throws SQLException {
        String sql = "DELETE FROM pets WHERE pet_id = ? AND shelter_id = ?";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, petId);
            pstmt.setInt(2, shelterId);
            
            int affectedRows = pstmt.executeUpdate();
            return affectedRows > 0;
            
        } finally {
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }
    
    // Get pet count by shelter (for stats)
    public int getPetCountByShelter(int shelterId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM pets WHERE shelter_id = ?";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            rs = pstmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1);
            }
            
            return 0;
            
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }
    
    // Search pets by name or species
    public List<Pets> searchPets(int shelterId, String searchTerm) throws SQLException {
        List<Pets> pets = new ArrayList<>();
        String sql = "SELECT * FROM pets WHERE shelter_id = ? AND (LOWER(name) LIKE LOWER(?) OR LOWER(species) LIKE LOWER(?)) ORDER BY created_at DESC";
        
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            pstmt.setString(2, "%" + searchTerm + "%");
            pstmt.setString(3, "%" + searchTerm + "%");
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Pets pet = resultSetToPet(rs);
                pets.add(pet);
            }
            
            return pets;
            
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }
    
    // Helper method to convert ResultSet to Pets object
    private Pets resultSetToPet(ResultSet rs) throws SQLException {
        Pets pet = new Pets();
        pet.setPetId(rs.getInt("pet_id"));
        pet.setShelterId(rs.getInt("shelter_id"));
        pet.setName(rs.getString("name"));
        pet.setSpecies(rs.getString("species"));
        pet.setBreed(rs.getString("breed"));
        
        int age = rs.getInt("age");
        pet.setAge(rs.wasNull() ? null : age);
        
        pet.setGender(rs.getString("gender"));
        pet.setSize(rs.getString("size"));
        pet.setColor(rs.getString("color"));
        pet.setDescription(rs.getString("description"));
        pet.setHealthStatus(rs.getString("health_status"));
        pet.setPhotoPath(rs.getString("photo_path"));
        pet.setCreatedAt(rs.getTimestamp("created_at"));
        
        return pet;
    }
}