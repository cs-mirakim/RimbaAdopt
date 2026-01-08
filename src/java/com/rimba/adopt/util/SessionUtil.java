package com.rimba.adopt.util;

import com.rimba.adopt.model.Users;
import javax.servlet.http.HttpSession;

public class SessionUtil {

    public static boolean isLoggedIn(HttpSession session) {
        return session != null && session.getAttribute("userId") != null;
    }

    public static int getUserId(HttpSession session) {
        if (session == null) {
            return -1;
        }
        Object userId = session.getAttribute("userId");
        return userId != null ? (Integer) userId : -1;
    }

    public static String getUserRole(HttpSession session) {
        if (session == null) {
            return null;
        }
        return (String) session.getAttribute("userRole");
    }

    public static String getUserName(HttpSession session) {
        if (session == null) {
            return null;
        }
        return (String) session.getAttribute("userName");
    }

    public static void setUserSession(HttpSession session, Users user) {
        if (session == null || user == null) {
            return;
        }

        session.setAttribute("userId", user.getUserId());
        session.setAttribute("userRole", user.getRole());
        session.setAttribute("userName", user.getName());
        session.setAttribute("userEmail", user.getEmail());
        session.setAttribute("userProfilePhoto", user.getProfilePhotoPath());

        session.setMaxInactiveInterval(30 * 60); // 30 menit
    }

    public static void invalidateSession(HttpSession session) {
        if (session != null) {
            session.invalidate();
        }
    }

    public static boolean isAdmin(HttpSession session) {
        return "admin".equals(getUserRole(session));
    }

    public static boolean isShelter(HttpSession session) {
        return "shelter".equals(getUserRole(session));
    }

    public static boolean isAdopter(HttpSession session) {
        return "adopter".equals(getUserRole(session));
    }

    public static boolean hasAccess(HttpSession session, String requiredRole) {
        String userRole = getUserRole(session);
        if (userRole == null) {
            return false;
        }

        switch (requiredRole) {
            case "admin":
                return "admin".equals(userRole);
            case "shelter":
                return "shelter".equals(userRole);
            case "adopter":
                return "adopter".equals(userRole);
            default:
                return false;
        }
    }

    public static String getUserProfilePhoto(HttpSession session) {
        if (session == null) {
            return null;
        }
        return (String) session.getAttribute("userProfilePhoto");
    }

}
