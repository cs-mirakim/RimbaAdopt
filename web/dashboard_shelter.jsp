<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.rimba.adopt.util.SessionUtil" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.List" %>

<%
    // Check if user is logged in and is shelter
    if (!SessionUtil.isLoggedIn(session)) {
        response.sendRedirect("index.jsp");
        return;
    }

    if (!SessionUtil.isShelter(session)) {
        response.sendRedirect("index.jsp");
        return;
    }
    
    // Get data from request attributes
    Integer totalPets = (Integer) request.getAttribute("totalPets");
    Integer pendingRequests = (Integer) request.getAttribute("pendingRequests");
    Integer approvedRequests = (Integer) request.getAttribute("approvedRequests");
    Integer rejectedRequests = (Integer) request.getAttribute("rejectedRequests");
    Integer cancelledRequests = (Integer) request.getAttribute("cancelledRequests");
    Double averageRating = (Double) request.getAttribute("averageRating");
    
    Map<String, Object> monthlyStats = (Map<String, Object>) request.getAttribute("monthlyStats");
    Map<String, Object> monthlyFeedbackStats = (Map<String, Object>) request.getAttribute("monthlyFeedbackStats");
    
    // Handle null values
    if (totalPets == null) totalPets = 0;
    if (pendingRequests == null) pendingRequests = 0;
    if (approvedRequests == null) approvedRequests = 0;
    if (rejectedRequests == null) rejectedRequests = 0;
    if (cancelledRequests == null) cancelledRequests = 0;
    if (averageRating == null) averageRating = 0.0;
    
    // Get shelter name from session
    String shelterName = SessionUtil.getUserName(session);
%>

<!DOCTYPE html>
<html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Shelter Dashboard - Rimba Adopt</title>
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
                    <!-- Banner Images -->
                    <div class="banner-container relative" style="height: 400px;">
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
                    <div class="absolute bottom-4 left-1/2 transform -translate-x-1/2 flex items-center justify-center">
                        <span class="dot active" onclick="currentSlide(1)"></span>
                        <span class="dot" onclick="currentSlide(2)"></span>
                        <span class="dot" onclick="currentSlide(3)"></span>
                        <span class="dot" onclick="currentSlide(4)"></span>
                        <span class="dot" onclick="currentSlide(5)"></span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Main Dashboard Content -->
        <main class="flex-1 p-4 pt-6 relative z-10 flex justify-center items-start mb-2">
            <div class="w-full bg-white py-8 px-6 rounded-xl shadow-md" style="max-width: 1450px;">

                <!-- Dashboard Title -->
                <div class="mb-8 pb-4 border-b border-gray-300">
                    <h1 class="text-4xl font-extrabold" style="color: #2F5D50;">Welcome Back, <%= shelterName != null ? shelterName : "Shelter Manager" %>!</h1>
                    <p class="mt-2 text-lg" style="color: #2B2B2B;">
                        Here's an overview of your shelter's pets, adoption requests, and feedback.
                    </p>
                </div>

                <!-- Statistics Cards -->
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
                    <!-- Total Pets Listed -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#2F5D50]">
                        <p class="text-sm font-medium text-[#2F5D50] mb-1">Total Pets Listed</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]"><%= totalPets %></p>
                    </div>

                    <!-- Pending Requests -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-gray-400">
                        <p class="text-sm font-medium text-gray-700 mb-1">Pending Requests</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]"><%= pendingRequests %></p>
                    </div>

                    <!-- Approved Requests -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#6DBF89]">
                        <p class="text-sm font-medium text-[#57A677] mb-1">Approved Requests</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]"><%= approvedRequests %></p>
                    </div>

                    <!-- Rejected Requests -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#B84A4A]">
                        <p class="text-sm font-medium text-[#B84A4A] mb-1">Rejected Requests</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]"><%= rejectedRequests %></p>
                    </div>

                    <!-- Cancelled Requests -->
                    <div class="bg-[#F6F3E7] p-5 rounded-lg shadow-sm border-l-4 border-[#C49A6C]">
                        <p class="text-sm font-medium text-[#C49A6C] mb-1">Cancelled Requests</p>
                        <p class="text-3xl font-bold text-[#2B2B2B]"><%= cancelledRequests %></p>
                    </div>
                </div>

                <!-- Request Overview Chart (Grouped Bar Chart) -->
                <div class="border border-[#E5E5E5] rounded-xl p-6 mb-8 shadow-sm">
                    <h2 class="text-xl font-semibold text-[#2B2B2B] mb-4">Adoption Request Overview (This Year)</h2>
                    <div class="relative" style="height: 400px;">
                        <canvas id="requestChart"></canvas>
                    </div>
                </div>

                <!-- Feedback Overview & Quick Links -->
                <div class="grid grid-cols-1 lg:grid-cols-4 gap-6">
                    <!-- Left area: Feedback Chart -->
                    <div class="lg:col-span-3 border border-[#E5E5E5] rounded-xl p-6 shadow-sm bg-white">
                        <h2 class="text-xl font-semibold text-[#2B2B2B] mb-4">Shelter Feedback Overview</h2>
                        <div class="relative w-full h-72 sm:h-80 lg:h-[350px]">
                            <canvas id="feedbackChart" class="w-full h-full"></canvas>
                        </div>
                    </div>

                    <!-- Quick Links (right column) -->
                    <div class="lg:col-span-1 border border-[#E5E5E5] rounded-xl p-6 shadow-sm flex flex-col">
                        <h2 class="text-xl font-semibold text-[#2B2B2B] mb-4">Quick Links</h2>

                        <div class="space-y-4">
                            <a href="manage_pets.jsp" class="flex items-center gap-3 p-4 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
                                </svg>
                                <span class="text-sm font-medium">Manage Pets</span>
                            </a>

                            <a href="manage_request.jsp" class="flex items-center gap-3 p-4 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                                </svg>
                                <span class="text-sm font-medium">Manage Requests</span>
                            </a>
                            
                            <a href="view_feedback.jsp" class="flex items-center gap-3 p-4 rounded-lg bg-[#2F5D50] text-white hover:bg-[#24483E] transition group w-full">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                      d="M8 10h.01M12 10h.01M16 10h.01M9 16H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-5l-5 5v-5z" />
                                </svg>
                                <span class="text-sm font-medium">View Feedback</span>
                            </a>
                        </div>
                        
                        <!-- Average Rating Display -->
                        <div class="mt-8 pt-6 border-t border-gray-200">
                            <h3 class="text-lg font-semibold text-[#2B2B2B] mb-2">Current Rating</h3>
                            <div class="flex items-center gap-2">
                                <div class="text-3xl font-bold text-[#2F5D50]">
                                    <%= String.format("%.1f", averageRating) %>
                                </div>
                                <div class="text-sm text-gray-600">/ 5.0</div>
                            </div>
                            <div class="mt-2 text-sm text-gray-500">
                                Based on customer feedback
                            </div>
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
                    slideIndex = 1
                }
                if (n < 1) {
                    slideIndex = slides.length
                }

                for (let i = 0; i < slides.length; i++) {
                    slides[i].classList.remove("active");
                }
                for (let i = 0; i < dots.length; i++) {
                    dots[i].classList.remove("active");
                }

                slides[slideIndex - 1].classList.add("active");
                dots[slideIndex - 1].classList.add("active");
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
                slideTimer = setInterval(() => {
                    slideIndex++;
                    showSlides(slideIndex);
                }, 5000);
            }

            // Initialize slideshow
            showSlides(slideIndex);
            startAutoSlide();

            // Prepare chart data from server-side variables
            <% 
                // Prepare monthly data for JavaScript
                List<String> months = null;
                Map<String, int[]> monthlyData = null;
                double[] monthlyRatings = null;
                
                if (monthlyStats != null) {
                    months = (List<String>) monthlyStats.get("months");
                    monthlyData = (Map<String, int[]>) monthlyStats.get("monthlyData");
                }
                
                if (monthlyFeedbackStats != null) {
                    monthlyRatings = (double[]) monthlyFeedbackStats.get("monthlyRatings");
                }
                
                // Default data if no real data
                int[] approvedData = new int[12];
                int[] pendingData = new int[12];
                int[] rejectedData = new int[12];
                int[] cancelledData = new int[12];
                double[] ratingData = new double[12];
                
                if (monthlyData != null) {
                    approvedData = monthlyData.getOrDefault("approved", new int[12]);
                    pendingData = monthlyData.getOrDefault("pending", new int[12]);
                    rejectedData = monthlyData.getOrDefault("rejected", new int[12]);
                    cancelledData = monthlyData.getOrDefault("cancelled", new int[12]);
                }
                
                if (monthlyRatings != null) {
                    ratingData = monthlyRatings;
                }
            %>

            // Request Overview Chart (Grouped Bar Chart)
            const reqCtx = document.getElementById('requestChart').getContext('2d');
            const requestChart = new Chart(reqCtx, {
                type: 'bar',
                data: {
                    labels: <%= months != null ? months.toString() : "['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']" %>,
                    datasets: [
                        {
                            label: 'Approved',
                            data: <%= java.util.Arrays.toString(approvedData) %>,
                            backgroundColor: '#6DBF89',
                            borderColor: '#57A677',
                            borderWidth: 1
                        },
                        {
                            label: 'Pending',
                            data: <%= java.util.Arrays.toString(pendingData) %>,
                            backgroundColor: '#A3A3A3',
                            borderColor: '#8A8A8A',
                            borderWidth: 1
                        },
                        {
                            label: 'Rejected',
                            data: <%= java.util.Arrays.toString(rejectedData) %>,
                            backgroundColor: '#B84A4A',
                            borderColor: '#9A3A3A',
                            borderWidth: 1
                        },
                        {
                            label: 'Cancelled',
                            data: <%= java.util.Arrays.toString(cancelledData) %>,
                            backgroundColor: '#C49A6C',
                            borderColor: '#A47A4C',
                            borderWidth: 1
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
                                text: 'Number of Requests'
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

            // Feedback Overview Chart (Line Chart - Average Rating per Month)
            const feedbackCtx = document.getElementById('feedbackChart').getContext('2d');
            const feedbackChart = new Chart(feedbackCtx, {
                type: 'line',
                data: {
                    labels: <%= months != null ? months.toString() : "['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']" %>,
                    datasets: [{
                        label: 'Average Rating',
                        data: <%= java.util.Arrays.toString(ratingData) %>,
                        borderColor: '#2F5D50',
                        backgroundColor: 'rgba(47, 93, 80, 0.1)',
                        borderWidth: 3,
                        tension: 0.4,
                        pointRadius: 6,
                        pointBackgroundColor: '#2F5D50',
                        pointBorderColor: '#FFFFFF',
                        pointBorderWidth: 2,
                        fill: true
                    }]
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
                            beginAtZero: false,
                            min: 0,
                            max: 5.5,
                            ticks: {
                                stepSize: 0.5,
                                callback: function (value) {
                                    return value.toFixed(1);
                                }
                            },
                            title: {
                                display: true,
                                text: 'Average Rating (1-5)'
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            position: 'top'
                        },
                        tooltip: {
                            callbacks: {
                                label: function (context) {
                                    return `Rating: ${context.parsed.y.toFixed(1)}/5`;
                                }
                            }
                        }
                    }
                }
            });
        </script>

    </body>
</html>