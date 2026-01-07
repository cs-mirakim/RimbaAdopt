package com.rimba.adopt.util;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

public class SessionUtil {

    // Check if user is logged in
    public static boolean isLoggedIn(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session != null && session.getAttribute("userId") != null;
    }

    // Get user ID from session
    public static Integer getUserId(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            Object userId = session.getAttribute("userId");
            if (userId instanceof Integer) {
                return (Integer) userId;
            } else if (userId instanceof String) {
                try {
                    return Integer.parseInt((String) userId);
                } catch (NumberFormatException e) {
                    return null;
                }
            }
        }
        return null;
    }

    // Get user role from session
    public static String getUserRole(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session != null ? (String) session.getAttribute("role") : null;
    }

    // Get user name from session
    public static String getUserName(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session != null ? (String) session.getAttribute("name") : null;
    }

    // Get profile photo path from session
    public static String getProfilePhotoPath(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        String defaultPath = request.getContextPath() + "/profile_picture/default.png";

        if (session != null) {
            String photoPath = (String) session.getAttribute("profilePhotoPath");

            // Jika null atau empty, return default
            if (photoPath == null || photoPath.trim().isEmpty()) {
                return defaultPath;
            }

            // Jika path sudah bermula dengan /, assume ia betul dari webapp root
            if (photoPath.startsWith("/")) {
                return photoPath;
            }

            // Jika path sudah ada "profile_picture/", add context path sahaja
            if (photoPath.startsWith("profile_picture/")) {
                return request.getContextPath() + "/" + photoPath;
            }

            // Jika path lain (http, https), return as is
            if (photoPath.startsWith("http")) {
                return photoPath;
            }

            // Fallback: return default
            return defaultPath;
        }

        return defaultPath;
    }

    // Check specific role
    public static boolean isAdmin(HttpServletRequest request) {
        return "admin".equals(getUserRole(request));
    }

    public static boolean isShelter(HttpServletRequest request) {
        return "shelter".equals(getUserRole(request));
    }

    public static boolean isAdopter(HttpServletRequest request) {
        return "adopter".equals(getUserRole(request));
    }

    // Get all session attributes for debugging
    public static String getSessionDebugInfo(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return "No session";
        }

        StringBuilder sb = new StringBuilder();
        sb.append("Session ID: ").append(session.getId()).append("\n");
        java.util.Enumeration<String> attrNames = session.getAttributeNames();
        while (attrNames.hasMoreElements()) {
            String name = attrNames.nextElement();
            Object value = session.getAttribute(name);
            sb.append(name).append(": ").append(value).append("\n");
        }
        return sb.toString();
    }
}
