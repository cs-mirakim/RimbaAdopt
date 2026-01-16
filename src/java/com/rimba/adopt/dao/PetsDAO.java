package com.rimba.adopt.dao;

import com.rimba.adopt.model.Pets;
import com.rimba.adopt.util.DatabaseConnection;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PetsDAO {

    // Create a new pet with adoption status
    public int createPet(Pets pet) throws SQLException {
        String sql = "INSERT INTO pets (shelter_id, name, species, breed, age, gender, size, color, description, health_status, photo_path, adoption_status) "
                + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            System.out.println("DEBUG: Creating pet for shelter ID: " + pet.getShelterId());
            
            pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);

            pstmt.setInt(1, pet.getShelterId());
            pstmt.setString(2, pet.getName());
            pstmt.setString(3, pet.getSpecies());

            // Breed - nullable
            if (pet.getBreed() != null && !pet.getBreed().isEmpty()) {
                pstmt.setString(4, pet.getBreed());
            } else {
                pstmt.setNull(4, Types.VARCHAR);
            }

            // Age - nullable
            if (pet.getAge() != null) {
                pstmt.setInt(5, pet.getAge());
            } else {
                pstmt.setNull(5, Types.INTEGER);
            }

            pstmt.setString(6, pet.getGender());
            pstmt.setString(7, pet.getSize());

            // Color - nullable
            if (pet.getColor() != null && !pet.getColor().isEmpty()) {
                pstmt.setString(8, pet.getColor());
            } else {
                pstmt.setNull(8, Types.VARCHAR);
            }

            // Description - nullable
            if (pet.getDescription() != null && !pet.getDescription().isEmpty()) {
                pstmt.setString(9, pet.getDescription());
            } else {
                pstmt.setNull(9, Types.CLOB);
            }

            // Health status - nullable
            if (pet.getHealthStatus() != null && !pet.getHealthStatus().isEmpty()) {
                pstmt.setString(10, pet.getHealthStatus());
            } else {
                pstmt.setNull(10, Types.VARCHAR);
            }

            // Photo path - nullable
            if (pet.getPhotoPath() != null && !pet.getPhotoPath().isEmpty()) {
                pstmt.setString(11, pet.getPhotoPath());
            } else {
                pstmt.setNull(11, Types.VARCHAR);
            }

            // Adoption status - NEW, default to 'available' if not set
            String adoptionStatus = pet.getAdoptionStatus();
            if (adoptionStatus != null && !adoptionStatus.isEmpty()) {
                pstmt.setString(12, adoptionStatus);
            } else {
                pstmt.setString(12, "available");
            }

            System.out.println("DEBUG: Executing SQL: " + sql);
            System.out.println("DEBUG: Pet data - Name: " + pet.getName() + ", Species: " + pet.getSpecies() + 
                             ", Gender: " + pet.getGender() + ", Status: " + adoptionStatus);

            int affectedRows = pstmt.executeUpdate();
            System.out.println("DEBUG: Affected rows: " + affectedRows);

            if (affectedRows > 0) {
                rs = pstmt.getGeneratedKeys();
                if (rs.next()) {
                    int generatedId = rs.getInt(1);
                    pet.setPetId(generatedId);
                    System.out.println("DEBUG: Generated pet ID: " + generatedId);
                    return generatedId;
                }
            }

            System.out.println("DEBUG: Insert failed, no generated ID");
            return -1; // Insert failed

        } catch (SQLException e) {
            System.err.println("ERROR in createPet: " + e.getMessage());
            e.printStackTrace();
            throw e;
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }
    
    

    // Get all pets for a specific shelter
    public List<Pets> getPetsByShelter(int shelterId) throws SQLException {
        List<Pets> pets = new ArrayList<Pets>();
        String sql = "SELECT * FROM pets WHERE shelter_id = ? ORDER BY created_at DESC";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            System.out.println("DEBUG: Getting pets for shelter ID: " + shelterId);
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            rs = pstmt.executeQuery();

            int count = 0;
            while (rs.next()) {
                count++;
                Pets pet = resultSetToPet(rs);
                pets.add(pet);
                System.out.println("DEBUG: Found pet #" + count + " - ID: " + pet.getPetId() + 
                                 ", Name: " + pet.getName() + 
                                 ", Status: " + pet.getAdoptionStatus());
            }

            System.out.println("DEBUG: Total pets found: " + pets.size());
            return pets;

        } catch (SQLException e) {
            System.err.println("ERROR in getPetsByShelter: " + e.getMessage());
            e.printStackTrace();
            throw e;
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }

    // Get available pets for a specific shelter (NEW)
    public List<Pets> getAvailablePetsByShelter(int shelterId) throws SQLException {
        List<Pets> pets = new ArrayList<Pets>();
        String sql = "SELECT * FROM pets WHERE shelter_id = ? AND adoption_status = 'available' ORDER BY created_at DESC";

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

    // Get pets by adoption status (NEW)
    public List<Pets> getPetsByStatus(int shelterId, String status) throws SQLException {
        List<Pets> pets = new ArrayList<Pets>();
        String sql = "SELECT * FROM pets WHERE shelter_id = ? AND adoption_status = ? ORDER BY created_at DESC";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            pstmt.setString(2, status);
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
            System.out.println("DEBUG: Getting pet by ID: " + petId + " for shelter: " + shelterId);
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, petId);
            pstmt.setInt(2, shelterId);
            rs = pstmt.executeQuery();

            if (rs.next()) {
                Pets pet = resultSetToPet(rs);
                System.out.println("DEBUG: Found pet - ID: " + petId + ", Name: " + pet.getName());
                return pet;
            }
            
            System.out.println("DEBUG: No pet found with ID: " + petId + " for shelter: " + shelterId);
            return null;

        } catch (SQLException e) {
            System.err.println("ERROR in getPetByIdAndShelter: " + e.getMessage());
            e.printStackTrace();
            throw e;
        } finally {
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }

    // Update pet with adoption status
    public boolean updatePet(Pets pet) throws SQLException {
        String sql = "UPDATE pets SET name = ?, species = ?, breed = ?, age = ?, gender = ?, "
                + "size = ?, color = ?, description = ?, health_status = ?, photo_path = ?, adoption_status = ? "
                + "WHERE pet_id = ? AND shelter_id = ?";

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            System.out.println("DEBUG: Updating pet ID: " + pet.getPetId() + " for shelter: " + pet.getShelterId());
            
            pstmt = conn.prepareStatement(sql);

            pstmt.setString(1, pet.getName());
            pstmt.setString(2, pet.getSpecies());

            // Breed - nullable
            if (pet.getBreed() != null && !pet.getBreed().isEmpty()) {
                pstmt.setString(3, pet.getBreed());
            } else {
                pstmt.setNull(3, Types.VARCHAR);
            }

            // Age - nullable
            if (pet.getAge() != null) {
                pstmt.setInt(4, pet.getAge());
            } else {
                pstmt.setNull(4, Types.INTEGER);
            }

            pstmt.setString(5, pet.getGender());
            pstmt.setString(6, pet.getSize());

            // Color - nullable
            if (pet.getColor() != null && !pet.getColor().isEmpty()) {
                pstmt.setString(7, pet.getColor());
            } else {
                pstmt.setNull(7, Types.VARCHAR);
            }

            // Description - nullable
            if (pet.getDescription() != null && !pet.getDescription().isEmpty()) {
                pstmt.setString(8, pet.getDescription());
            } else {
                pstmt.setNull(8, Types.CLOB);
            }

            // Health status - nullable
            if (pet.getHealthStatus() != null && !pet.getHealthStatus().isEmpty()) {
                pstmt.setString(9, pet.getHealthStatus());
            } else {
                pstmt.setNull(9, Types.VARCHAR);
            }

            // Photo path - nullable
            if (pet.getPhotoPath() != null && !pet.getPhotoPath().isEmpty()) {
                pstmt.setString(10, pet.getPhotoPath());
            } else {
                pstmt.setNull(10, Types.VARCHAR);
            }

            // Adoption status - NEW
            String adoptionStatus = pet.getAdoptionStatus();
            if (adoptionStatus != null && !adoptionStatus.isEmpty()) {
                pstmt.setString(11, adoptionStatus);
            } else {
                pstmt.setString(11, "available");
            }

            pstmt.setInt(12, pet.getPetId());
            pstmt.setInt(13, pet.getShelterId());

            System.out.println("DEBUG: Executing update SQL");
            int affectedRows = pstmt.executeUpdate();
            System.out.println("DEBUG: Update affected rows: " + affectedRows);
            
            return affectedRows > 0;

        } catch (SQLException e) {
            System.err.println("ERROR in updatePet: " + e.getMessage());
            e.printStackTrace();
            throw e;
        } finally {
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }

    // Update only adoption status (NEW)
    public boolean updateAdoptionStatus(int petId, int shelterId, String adoptionStatus) throws SQLException {
        String sql = "UPDATE pets SET adoption_status = ? WHERE pet_id = ? AND shelter_id = ?";

        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            conn = DatabaseConnection.getConnection();
            System.out.println("DEBUG: Updating adoption status for pet ID: " + petId + 
                             " to: " + adoptionStatus + " for shelter: " + shelterId);
            
            pstmt = conn.prepareStatement(sql);

            pstmt.setString(1, adoptionStatus);
            pstmt.setInt(2, petId);
            pstmt.setInt(3, shelterId);

            int affectedRows = pstmt.executeUpdate();
            System.out.println("DEBUG: Status update affected rows: " + affectedRows);
            return affectedRows > 0;

        } catch (SQLException e) {
            System.err.println("ERROR in updateAdoptionStatus: " + e.getMessage());
            e.printStackTrace();
            throw e;
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
            System.out.println("DEBUG: Deleting pet ID: " + petId + " for shelter: " + shelterId);
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, petId);
            pstmt.setInt(2, shelterId);

            int affectedRows = pstmt.executeUpdate();
            System.out.println("DEBUG: Delete affected rows: " + affectedRows);
            return affectedRows > 0;

        } catch (SQLException e) {
            System.err.println("ERROR in deletePet: " + e.getMessage());
            e.printStackTrace();
            throw e;
        } finally {
            if (pstmt != null) pstmt.close();
            DatabaseConnection.closeConnection(conn);
        }
    }

    // Get pet count by shelter
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

    // Get pet count by status (NEW)
    public int getPetCountByStatus(int shelterId, String status) throws SQLException {
        String sql = "SELECT COUNT(*) FROM pets WHERE shelter_id = ? AND adoption_status = ?";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            pstmt.setString(2, status);
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
        List<Pets> pets = new ArrayList<Pets>();
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

    // Search pets by name or species with status filter (NEW)
    public List<Pets> searchPetsByStatus(int shelterId, String searchTerm, String status) throws SQLException {
        List<Pets> pets = new ArrayList<Pets>();
        String sql = "SELECT * FROM pets WHERE shelter_id = ? AND adoption_status = ? AND (LOWER(name) LIKE LOWER(?) OR LOWER(species) LIKE LOWER(?)) ORDER BY created_at DESC";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, shelterId);
            pstmt.setString(2, status);
            pstmt.setString(3, "%" + searchTerm + "%");
            pstmt.setString(4, "%" + searchTerm + "%");
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

    // Get all pets (for admin or public listing)
    public List<Pets> getAllPets() throws SQLException {
        List<Pets> pets = new ArrayList<Pets>();
        String sql = "SELECT * FROM pets ORDER BY created_at DESC";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
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
// ========== METHODS FOR DASHBOARD SHELTER ==========

// Count pets by shelter - NEW METHOD
public int countPetsByShelter(int shelterId) throws SQLException {
    String query = "SELECT COUNT(*) FROM pets WHERE shelter_id = ? AND status = 'available'";
    
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
        if (rs != null) try { rs.close(); } catch (SQLException e) {}
        if (pstmt != null) try { pstmt.close(); } catch (SQLException e) {}
        DatabaseConnection.closeConnection(conn);
    }
}
    // Get all available pets (for public adoption listing)
    public List<Pets> getAllAvailablePets() throws SQLException {
        List<Pets> pets = new ArrayList<Pets>();
        String sql = "SELECT p.*, s.shelter_name FROM pets p "
                   + "JOIN shelter s ON p.shelter_id = s.shelter_id "
                   + "WHERE p.adoption_status = 'available' AND s.approval_status = 'approved' "
                   + "ORDER BY p.created_at DESC";

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DatabaseConnection.getConnection();
            pstmt = conn.prepareStatement(sql);
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
        
        try {
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
            
            // Handle adoption_status - might be NULL
            String adoptionStatus = rs.getString("adoption_status");
            if (adoptionStatus != null && !adoptionStatus.isEmpty()) {
                pet.setAdoptionStatus(adoptionStatus);
            } else {
                pet.setAdoptionStatus("available"); // Default value
            }
            
            pet.setCreatedAt(rs.getTimestamp("created_at"));

            // Try to get shelter_name if exists (for getAllAvailablePets)
            try {
                String shelterName = rs.getString("shelter_name");
                if (shelterName != null) {
                    // You might want to store this in a different way
                    // For now, just logging
                    System.out.println("DEBUG: Found shelter name: " + shelterName + " for pet: " + pet.getName());
                }
            } catch (SQLException e) {
                // Column doesn't exist, ignore
            }

        } catch (SQLException e) {
            System.err.println("ERROR in resultSetToPet: " + e.getMessage());
            System.err.println("Column names in result set:");
            try {
                java.sql.ResultSetMetaData metaData = rs.getMetaData();
                int columnCount = metaData.getColumnCount();
                for (int i = 1; i <= columnCount; i++) {
                    System.err.println("  Column " + i + ": " + metaData.getColumnName(i));
                }
            } catch (SQLException ex) {
                System.err.println("Failed to get metadata: " + ex.getMessage());
            }
            throw e;
        }

        return pet;
    }

 
}

