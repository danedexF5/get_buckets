// scripts.js - Client-side JavaScript for NBA Stats App

// Wait for document to be ready
$(document).ready(function() {
  
  // Add year validation
  $("#year").on("input", function() {
    const yearInput = $(this);
    const year = parseInt(yearInput.val());
    const currentYear = new Date().getFullYear();
    
    // Check if year is valid
    if (isNaN(year) || year < 1946 || year > currentYear) {
      yearInput.addClass("is-invalid");
      $("#submit").prop("disabled", true);
    } else {
      yearInput.removeClass("is-invalid");
      $("#submit").prop("disabled", false);
    }
  });
  
  // Initialize tooltips
  $("[data-toggle='tooltip']").tooltip();
  
  // Add smooth scrolling to results when data is loaded
  $(document).on("shiny:value", function(event) {
    if (event.name === "resultsTable" && !$("#resultsTable").is(":empty")) {
      $('html, body').animate({
        scrollTop: $("#resultsTable").offset().top - 20
      }, 500);
    }
  });
  
  // Enhance mobile experience
  if (window.innerWidth < 768) {
    // Add swipe to navigate between sidebar tabs on mobile
    const sidebarMenu = document.querySelector(".sidebar-menu");
    let touchStartX = 0;
    
    document.addEventListener('touchstart', function(e) {
      touchStartX = e.changedTouches[0].screenX;
    }, false);
    
    document.addEventListener('touchend', function(e) {
      const touchEndX = e.changedTouches[0].screenX;
      const diff = touchEndX - touchStartX;
      
      // If swipe distance is significant
      if (Math.abs(diff) > 50) {
        // Open sidebar menu on swipe right
        if (diff > 0) {
          $("body").addClass("sidebar-open");
        } 
        // Close sidebar menu on swipe left
        else {
          $("body").removeClass("sidebar-open");
        }
      }
    }, false);
  }
  
  // Add keyboard shortcuts
  $(document).keydown(function(e) {
    // Submit form with Enter when focus is on year input
    if (e.keyCode === 13 && $("#year").is(":focus")) {
      $("#submit").click();
    }
    
    // Use Escape key to clear notifications
    if (e.keyCode === 27) {
      $(".shiny-notification").remove();
    }
  });
  
  // Add animation to the results table
  $(document).on("shiny:value", function(event) {
    if (event.name === "resultsTable") {
      $("#resultsTable").hide().fadeIn(500);
    }
  });
  
  // Enhance download button with confirmation on mobile
  if (window.innerWidth < 768) {
    $("#downloadData").on("click", function(e) {
      if (!confirm("Download CSV file?")) {
        e.preventDefault();
        return false;
      }
    });
  }
});
    