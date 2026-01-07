package com.rimba.adopt.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author amirh
 */
public class dbConnection {

    private static final String DB_URL = "jdbc:derby://localhost:1527/rimbaPetAdoptionDB";
    private static final String DB_USER = "app";
    private static final String DB_PASSWORD = "app";

    static {
        try {
            Class.forName("org.apache.derby.jdbc.ClientDriver");
            System.out.println("Derby JDBC Driver loaded successfully.");
        } catch (ClassNotFoundException ex) {
            Logger.getLogger(dbConnection.class.getName()).log(Level.SEVERE,
                    "Derby JDBC Driver not found!", ex);
        }
    }

    public static Connection getConnection() throws SQLException {
        try {
            Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
            System.out.println("Database connection established successfully.");
            return conn;
        } catch (SQLException ex) {
            Logger.getLogger(dbConnection.class.getName()).log(Level.SEVERE,
                    "Failed to connect to database!", ex);
            throw ex;
        }
    }

    public static boolean testConnection() {
        try (Connection conn = getConnection()) {
            return conn != null && !conn.isClosed();
        } catch (SQLException ex) {
            Logger.getLogger(dbConnection.class.getName()).log(Level.SEVERE,
                    "Connection test failed!", ex);
            return false;
        }
    }

    public static String getDbUrl() {
        return DB_URL;
    }
}
