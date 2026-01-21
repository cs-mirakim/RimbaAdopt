<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="com.rimba.adopt.dao.AdoptionRequestDAO" %>
<%@ page import="com.rimba.adopt.dao.LostReportDAO" %>
<%@page import="com.rimba.adopt.util.DatabaseConnection"%>
<%@page import="java.sql.Connection"%>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>

<%
    // Check if user is logged in and is adopter
    if (!SessionUtil.isLoggedIn(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    if (!SessionUtil.isAdopter(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    // Get adopter ID from session
    Integer adopterId = (Integer) session.getAttribute("userId");

    // Initialize DAOs
    AdoptionRequestDAO adoptionDAO = new AdoptionRequestDAO();
    LostReportDAO lostReportDAO = new LostReportDAO();

    // Variables for statistics
    int totalApplications = 0;
    int pendingApplications = 0;
    int approvedApplications = 0;
    int rejectedApplications = 0;
    int cancelledApplications = 0;

    int totalLostReports = 0;
    int totalFound = 0;
    int stillLost = 0;

    // Monthly data for charts
    List<Integer> monthlyApproved = new ArrayList<Integer>();
    List<Integer> monthlyPending = new ArrayList<Integer>();
    List<Integer> monthlyRejected = new ArrayList<Integer>();
    List<Integer> monthlyCancelled = new ArrayList<Integer>();

    List<Integer> monthlyLost = new ArrayList<Integer>();
    List<Integer> monthlyFound = new ArrayList<Integer>();

    try {
        // Get adoption statistics for this adopter
        // Since we don't have getAdoptionStatsByAdopter method, we'll create temporary stats

        // For Lost Reports
        totalLostReports = lostReportDAO.countLostReportsByStatus("lost")
                + lostReportDAO.countLostReportsByStatus("found");
        totalFound = lostReportDAO.countLostReportsByStatus("found");
        stillLost = lostReportDAO.countLostReportsByStatus("lost");

        // Generate monthly data with simple logic
        // In real implementation, you should create proper methods in DAO
        // Initialize lists with 12 months of zeros
        for (int i = 0; i < 12; i++) {
            monthlyApproved.add(0);
            monthlyPending.add(0);
            monthlyRejected.add(0);
            monthlyCancelled.add(0);
            monthlyLost.add(0);
            monthlyFound.add(0);
        }

        // Simple calculation for demo (you should replace with actual DAO calls)
        // Example: put some sample data
        monthlyApproved.set(0, 1); // Jan
        monthlyApproved.set(1, 2); // Feb
        monthlyApproved.set(2, 1); // Mar

        monthlyPending.set(0, 1);
        monthlyPending.set(1, 1);
        monthlyPending.set(2, 0);

        monthlyRejected.set(2, 1);

        monthlyLost.set(0, 2);
        monthlyLost.set(1, 3);
        monthlyFound.set(0, 1);
        monthlyFound.set(1, 2);

        // Calculate totals manually (old Java way)
        int approvedSum = 0;
        int pendingSum = 0;
        int rejectedSum = 0;
        int cancelledSum = 0;

        for (Integer num : monthlyApproved) {
            approvedSum += num;
        }
        for (Integer num : monthlyPending) {
            pendingSum += num;
        }
        for (Integer num : monthlyRejected) {
            rejectedSum += num;
        }
        for (Integer num : monthlyCancelled) {
            cancelledSum += num;
        }

        approvedApplications = approvedSum;
        pendingApplications = pendingSum;
        rejectedApplications = rejectedSum;
        cancelledApplications = cancelledSum;

        totalApplications = approvedApplications + pendingApplications
                + rejectedApplications + cancelledApplications;

    } catch (Exception e) {
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Adopter Dashboard - Rimba Adopt</title>
        <script src="https://cdn.tailwindcss.com"></script>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/3.9.1/chart.min.js"></script>
        <style>
            .banner-slide {
                display: none;
                animation: slideIn 0.5s ease-in-out;
            }
            .banner-slide.active {
                display: block;
            }
            @keyframes slideIn {
                from {
                    opacity: 0;
                    transform: translateX(100%);
                }
                to {
                    opacity: 1;
                    transform: translateX(0);
                }
            }
            .dot {
                height: 12px;
                width: 12px;
                margin: 0 4px;
                background-color: rgba(255, 255, 255, 0.5);
                border-radius: 50%;
                display: inline-block;
                transition: background-color 0.3s ease;
                cursor: pointer;
            }
            .dot.active {
                background-color: #FFFFFF;
            }
        </style>
    </head>
    <body class="flex flex-col min-h-screen relative bg-[#F6F3E7]">

        <!-- Header container -->
        <jsp:include page="includes/header.jsp" />

        <!-- Banner slideshow section -->
        <div class="p-4 pt-6 relative z-10 flex justify-center items-start">
            <div class="w-full" style="max-width: 1450px;">
                <div class="relative overflow-hidden rounded-xl shadow-lg">
                    <!-- Banner Images - Get from database -->
                    <div class="banner-container relative" style="height: 400px;">
                        <%
                            Connection bannerConn = null;
                            java.sql.PreparedStatement bannerPstmt = null;
                            java.sql.ResultSet bannerRs = null;
                            try {
                                bannerConn = DatabaseConnection.getConnection();
                                String bannerSql = "SELECT image_path FROM awareness_banner WHERE status = 'visible' ORDER BY COALESCE(display_order, 999) ASC";
                                bannerPstmt = bannerConn.prepareStatement(bannerSql);
                                bannerRs = bannerPstmt.executeQuery();

                                int bannerIndex = 0;
                                while (bannerRs.next()) {
                                    String imagePath = bannerRs.getString("image_path");
                                    if (imagePath != null && !imagePath.isEmpty()) {
                        %>
                        <div class="banner-slide <%= bannerIndex == 0 ? "active" : ""%>">
                            <img src="<%= imagePath%>" alt="Banner <%= bannerIndex + 1%>" class="w-full h-full object-cover">
                        </div>
                        <%
                                    bannerIndex++;
                                }
                            }

                            // If no banners in database, use static defaults
                            if (bannerIndex == 0) {
                        %>
                        <div class="banner-slide active">
                            <img src="banner/banner1.jpg" alt="Banner 1" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner2.jpg" alt="Banner 2" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner3.jpg" alt="Banner 3" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner4.jpg" alt="Banner 4" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner5.jpg" alt="Banner 5" class="w-full h-full object-cover">
                        </div>
                        <%
                            }
                        } catch (Exception e) {
                            // Fallback to static banners if error
                        %>
                        <div class="banner-slide active">
                            <img src="banner/banner1.jpg" alt="Banner 1" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner2.jpg" alt="Banner 2" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner3.jpg" alt="Banner 3" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner4.jpg" alt="Banner 4" class="w-full h-full object-cover">
                        </div>
                        <div class="banner-slide">
                            <img src="banner/banner5.jpg" alt="Banner 5" class="w-full h-full object-cover">
                        </div>
                        <%
                            } finally {
                                try {
                                    if (bannerRs != null) {
                                        bannerRs.close();
                                    }
                                } catch (Exception e) {
                                }
                                try {
                                    if (bannerPstmt != null) {
                                        bannerPstmt.close();
                                    }
                                } catch (Exception e) {
                                }
                                try {
                                    if (bannerConn != null) {
                                        bannerConn.close();
                                    }
                                } catch (Exception e) {
                                }
                            }
                        %>

                        <!-- Navigation Arrows -->
                        <button onclick="changeSlide(-1)" class="absolute left-4 top-1/2 transform -translate-y-1/2 bg-black/30 hover:bg-black/50 text-white p-3 rounded-full transition">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"></path>
                            </svg>
                        </button>
                        <button onclick="changeSlide(1)" class="absolute right-4 top-1/2 transform -translate-y-1/2 bg-black/30 hover:bg-black/50 text-white p-3 rounded-full transition">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7"></path>
                            </svg>
                        </button>
                    </div>

                    <!-- Dots Indicator -->
                    <div class="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex items-center justify-center" id="dotsContainer">
                        <!-- Dots will be generated by JavaScript -->
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Dashboard Content -->
        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start mb-2">
            <div class="w-full bg-white py-8 px-6 rounded-xl shadow-md" style="max-width: 1450px;">

                <!-- Dashboard Title -->
                <div class="mb-8 pb-4 border-b border-gray-300">
                    <h1 class="text-4xl font-extrabold" style="color: #2F5D50;">Welcome Back, Adopter!</h1>
                    <p class="mt-2 text-lg" style="color: #2B2B2B;">
                        Here's an overview of your adoption activities and lost animal reports.
                    </p>
                </div>

                <!-- Statistics Cards -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
                    <!-- Total Applications -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#2F5D50]">
                        <p class="text-sm font-medium text-[#2F5D50] mb-1">Total Applications</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]"><%= totalApplications%></p>
                    </div>

                    <!-- Pending -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-gray-400">
                        <p class="text-sm font-medium text-gray-700 mb-1">Pending</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]"><%= pendingApplications%></p>
                    </div>

                    <!-- Approved -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#6DBF89]">
                        <p class="text-sm font-medium text-[#57A677] mb-1">Approved</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]"><%= approvedApplications%></p>
                    </div>

                    <!-- Rejected -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#B84A4A]">
                        <p class="text-sm font-medium text-[#B84A4A] mb-1">Rejected</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]"><%= rejectedApplications%></p>
                    </div>

                    <!-- Cancelled -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#C49A6C]">
                        <p class="text-sm font-medium text-[#C49A6C] mb-1">Cancelled</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]"><%= cancelledApplications%></p>
                    </div>
                </div>

                <!-- Application Overview Chart -->
                <div class="border border-[#E5E5E5] rounded-xl p-6 mb-8 shadow-sm">
                    <h2 class="text-xl font-semibold text-[#2B2B2B] mb-4">Application Overview</h2>
                    <div class="relative" style="height: 400px;">
                        <canvas id="applicationChart"></canvas>
                    </div>
                </div>

                <!-- Lost Animal Overview & Quick Links -->
                <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
                    <!-- Left area: stats (on top) + chart (below) -->
                    <div class="lg:col-span-3 flex flex-col gap-6">
                        <!-- Stats row -->
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <div class="bg-red-50 p-5 rounded-lg shadow-sm border-l-4 border-[#B84A4A]">
                                <p class="text-sm font-medium text-[#B84A4A] mb-1">Total Lost Reports</p>
                                <p class="text-3xl font-bold text-[#2B2B2B]"><%= totalLostReports%></p>
                            </div>

                            <div class="bg-green-50 p-5 rounded-lg shadow-sm border-l-4 border-[#6DBF89]">
                                <p class="text-sm font-medium text-[#57A677] mb-1">Total Found</p>
                                <p class="text-3xl font-bold text-[#2B2B2B]"><%= totalFound%></p>
                            </div>
                        </div>

                        <!-- Chart card -->
                        <div class="border border-[#E5E5E5] rounded-xl p-6 shadow-sm bg-white">
                            <h2 class="text-xl font-semibold text-[#2B2B2B] mb-4">Lost Animal Report Overview</h2>
                            <div class="relative w-full h-72 sm:h-80 lg:h-[350px]">
                                <canvas id="lostAnimalChart" class="w-full h-full"></canvas>
                            </div>
                        </div>
                    </div>

                    <!-- Quick Links (right column) -->
                    <div class="lg:col-span-1 border border-[#E5E5E5] rounded-xl p-6 shadow-sm flex flex-col">
                        <h2 class="text-xl font-semibold text-[#2B2B2B] mb-4">Quick Links</h2>

                        <!-- scrollable links to avoid stretching the whole column -->
                        <div class="space-y-3 overflow-y-auto">
                            <a href="dashboard_adopter.jsp" class="flex items-center gap-3 p-3 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
                                </svg>
                                <span class="text-sm font-medium">Dashboard</span>
                            </a>

                            <a href="monitor_application.jsp" class="flex items-center gap-3 p-3 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                                </svg>
                                <span class="text-sm font-medium">Monitor Applications</span>
                            </a>

                            <a href="monitor_lost.jsp" class="flex items-center gap-3 p-3 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                                </svg>
                                <span class="text-sm font-medium">Monitor Lost Animal</span>
                            </a>

                            <a href="feedback_list.jsp" class="flex items-center gap-3 p-3 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
                                </svg>
                                <span class="text-sm font-medium">Monitor Feedback</span>
                            </a>

                            <a href="pet_list.jsp" class="flex items-center gap-3 p-3 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M14 10h4.764a2 2 0 011.789 2.894l-3.5 7A2 2 0 0115.263 21h-4.017c-.163 0-.326-.02-.485-.06L7 20m7-10V5a2 2 0 00-2-2h-.095c-.5 0-.905.405-.905.905 0 
                                      .714-.211 1.412-.608 2.006L7 11v9m7-10h-2M7 20H5a2 2 0 01-2-2v-6a2 2 0 012-2h2.5" />
                                </svg>
                                <span class="text-sm font-medium">Pet List</span>
                            </a>

                            <a href="shelter_list.jsp" class="flex items-center gap-3 p-3 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
                                </svg>
                                <span class="text-sm font-medium">Shelter List</span>
                            </a>

                            <a href="lost_animal.jsp" class="flex items-center gap-3 p-3 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                                </svg>
                                <span class="text-sm font-medium">Lost Animal List</span>
                            </a>
                        </div>
                    </div>
                </div>

            </div>
        </main>

        <!-- Footer container -->
        <jsp:include page="includes/footer.jsp" />

        <!-- Sidebar container -->
        <jsp:include page="includes/sidebar.jsp" />

        <!-- Load sidebar.js -->
        <script src="includes/sidebar.js"></script>

        <script>
                            // Banner Slideshow
                            let slideIndex = 1;
                            let slideTimer;

                            function showSlides(n) {
                                let slides = document.getElementsByClassName("banner-slide");
                                let dots = document.getElementsByClassName("dot");

                                if (n > slides.length) {
                                    slideIndex = 1;
                                }
                                if (n < 1) {
                                    slideIndex = slides.length;
                                }

                                for (let i = 0; i < slides.length; i++) {
                                    slides[i].classList.remove("active");
                                }
                                for (let i = 0; i < dots.length; i++) {
                                    dots[i].classList.remove("active");
                                }

                                if (slides[slideIndex - 1]) {
                                    slides[slideIndex - 1].classList.add("active");
                                }
                                if (dots[slideIndex - 1]) {
                                    dots[slideIndex - 1].classList.add("active");
                                }
                            }

                            function changeSlide(n) {
                                clearInterval(slideTimer);
                                showSlides(slideIndex += n);
                                startAutoSlide();
                            }

                            function currentSlide(n) {
                                clearInterval(slideTimer);
                                showSlides(slideIndex = n);
                                startAutoSlide();
                            }

                            function startAutoSlide() {
                                let slides = document.getElementsByClassName("banner-slide");
                                if (slides.length > 0) {
                                    slideTimer = setInterval(() => {
                                        slideIndex++;
                                        showSlides(slideIndex);
                                    }, 5000);
                                }
                            }

                            // Generate dots based on number of slides
                            function generateDots() {
                                let slides = document.getElementsByClassName("banner-slide");
                                let dotsContainer = document.getElementById("dotsContainer");
                                if (slides.length > 0 && dotsContainer) {
                                    dotsContainer.innerHTML = '';
                                    for (let i = 1; i <= slides.length; i++) {
                                        let dot = document.createElement("span");
                                        dot.className = i === 1 ? "dot active" : "dot";
                                        dot.onclick = function () {
                                            currentSlide(i);
                                        };
                                        dotsContainer.appendChild(dot);
                                    }
                                }
                            }

                            // Initialize slideshow
                            document.addEventListener('DOMContentLoaded', function () {
                                generateDots();
                                showSlides(slideIndex);
                                startAutoSlide();
                            });

                            // Application Overview Chart (Stacked Bar)
                            const appCtx = document.getElementById('applicationChart').getContext('2d');
                            const applicationChart = new Chart(appCtx, {
                                type: 'bar',
                                data: {
                                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                                    datasets: [
                                        {
                                            label: 'Approved',
                                            data: <%= monthlyApproved%>,
                                            backgroundColor: '#6DBF89',
                                            stack: 'stack0'
                                        },
                                        {
                                            label: 'Pending',
                                            data: <%= monthlyPending%>,
                                            backgroundColor: '#A3A3A3',
                                            stack: 'stack0'
                                        },
                                        {
                                            label: 'Rejected',
                                            data: <%= monthlyRejected%>,
                                            backgroundColor: '#B84A4A',
                                            stack: 'stack0'
                                        },
                                        {
                                            label: 'Cancelled',
                                            data: <%= monthlyCancelled%>,
                                            backgroundColor: '#C49A6C',
                                            stack: 'stack0'
                                        }
                                    ]
                                },
                                options: {
                                    responsive: true,
                                    maintainAspectRatio: false,
                                    scales: {
                                        x: {
                                            stacked: true,
                                            grid: {
                                                display: false
                                            },
                                            title: {
                                                display: true,
                                                text: 'Month'
                                            }
                                        },
                                        y: {
                                            stacked: true,
                                            beginAtZero: true,
                                            ticks: {
                                                stepSize: 1,
                                                precision: 0
                                            },
                                            title: {
                                                display: true,
                                                text: 'Number of Applications'
                                            }
                                        }
                                    },
                                    plugins: {
                                        legend: {
                                            position: 'top'
                                        },
                                        tooltip: {
                                            mode: 'index',
                                            intersect: false
                                        }
                                    }
                                }
                            });

                            // Lost Animal Overview Chart (Line Chart)
                            const lostCtx = document.getElementById('lostAnimalChart').getContext('2d');
                            const lostAnimalChart = new Chart(lostCtx, {
                                type: 'line',
                                data: {
                                    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                                    datasets: [
                                        {
                                            label: 'Still Lost',
                                            data: <%= monthlyLost%>,
                                            borderColor: '#B84A4A',
                                            backgroundColor: 'rgba(184, 74, 74, 0.1)',
                                            borderWidth: 2,
                                            borderDash: [5, 5],
                                            tension: 0.4,
                                            pointRadius: 4,
                                            pointBackgroundColor: '#B84A6A',
                                            fill: true
                                        },
                                        {
                                            label: 'Found',
                                            data: <%= monthlyFound%>,
                                            borderColor: '#6DBF89',
                                            backgroundColor: 'rgba(109, 191, 137, 0.1)',
                                            borderWidth: 2,
                                            borderDash: [5, 5],
                                            tension: 0.4,
                                            pointRadius: 4,
                                            pointBackgroundColor: '#6DBF89',
                                            fill: true
                                        }
                                    ]
                                },
                                options: {
                                    responsive: true,
                                    maintainAspectRatio: false,
                                    scales: {
                                        x: {
                                            grid: {
                                                display: false
                                            },
                                            title: {
                                                display: true,
                                                text: 'Month'
                                            }
                                        },
                                        y: {
                                            beginAtZero: true,
                                            ticks: {
                                                stepSize: 1,
                                                precision: 0
                                            },
                                            title: {
                                                display: true,
                                                text: 'Number of Reports'
                                            }
                                        }
                                    },
                                    plugins: {
                                        legend: {
                                            position: 'top'
                                        },
                                        tooltip: {
                                            mode: 'index',
                                            intersect: false
                                        }
                                    }
                                }
                            });
        </script>

    </body>
</html>