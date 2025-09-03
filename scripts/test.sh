#!/bin/bash

# Flutter Test Automation Script
# This script provides comprehensive test running capabilities for the project

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [TEST_TYPE]"
    echo ""
    echo "TEST_TYPE options:"
    echo "  unit         Run unit tests only"
    echo "  widget       Run widget tests only"
    echo "  integration  Run integration tests only"
    echo "  privacy      Run privacy compliance tests only"
    echo "  all          Run all tests (default)"
    echo ""
    echo "OPTIONS:"
    echo "  --coverage   Generate coverage report"
    echo "  --html       Generate HTML coverage report (requires lcov)"
    echo "  --verbose    Run with verbose output"
    echo "  --help, -h   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 unit                    # Run unit tests"
    echo "  $0 privacy                 # Run privacy compliance tests"
    echo "  $0 all --coverage          # Run all tests with coverage"
    echo "  $0 unit --coverage --html  # Run unit tests with HTML coverage"
}

# Function to check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    # Check for Flutter
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        exit 1
    fi
    
    # Check for lcov if HTML coverage is requested
    if [[ "$GENERATE_HTML" == "true" ]] && ! command -v lcov &> /dev/null; then
        print_warning "lcov is not installed. HTML coverage report will not be generated."
        print_info "Install lcov with: brew install lcov (macOS) or apt-get install lcov (Ubuntu)"
        GENERATE_HTML="false"
    fi
    
    print_success "Dependencies check completed"
}

# Function to run tests
run_tests() {
    local test_type=$1
    local coverage_flag=""
    local verbose_flag=""
    
    if [[ "$GENERATE_COVERAGE" == "true" ]]; then
        coverage_flag="--coverage"
        print_info "Coverage reporting enabled"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        verbose_flag="--verbose"
        print_info "Verbose output enabled"
    fi
    
    print_info "Running $test_type tests..."
    
    case $test_type in
        "unit")
            flutter test test/unit/ $coverage_flag $verbose_flag
            ;;
        "widget")
            flutter test test/widget/ $coverage_flag $verbose_flag
            ;;
        "integration")
            if [ -d "test/integration" ]; then
                flutter test test/integration/ $coverage_flag $verbose_flag
            else
                print_warning "No integration tests found"
            fi
            ;;
        "privacy")
            print_info "Running privacy compliance tests (COPPA/FERPA/GDPR)..."
            flutter test test/unit/privacy_compliance_test.dart $coverage_flag $verbose_flag
            flutter test test/integration/privacy_integration_test.dart $coverage_flag $verbose_flag
            flutter test test/widget/privacy_ui_test.dart $coverage_flag $verbose_flag
            ;;
        "all")
            flutter test $coverage_flag $verbose_flag
            ;;
        *)
            print_error "Unknown test type: $test_type"
            show_usage
            exit 1
            ;;
    esac
    
    if [ $? -eq 0 ]; then
        print_success "$test_type tests completed successfully"
    else
        print_error "$test_type tests failed"
        exit 1
    fi
}

# Function to generate HTML coverage report
generate_html_coverage() {
    if [[ "$GENERATE_HTML" == "true" ]] && [[ "$GENERATE_COVERAGE" == "true" ]]; then
        print_info "Generating HTML coverage report..."
        
        if [ -f "coverage/lcov.info" ]; then
            # Create coverage directory if it doesn't exist
            mkdir -p coverage/html
            
            # Generate HTML report
            genhtml coverage/lcov.info -o coverage/html
            
            if [ $? -eq 0 ]; then
                print_success "HTML coverage report generated in coverage/html/"
                print_info "Open coverage/html/index.html in your browser to view the report"
            else
                print_error "Failed to generate HTML coverage report"
            fi
        else
            print_warning "No coverage data found. Run tests with --coverage flag first."
        fi
    fi
}

# Function to show test summary
show_test_summary() {
    local test_type=$1
    
    print_info "Test Summary:"
    echo "  Test Type: $test_type"
    echo "  Coverage: $([ "$GENERATE_COVERAGE" == "true" ] && echo "Enabled" || echo "Disabled")"
    echo "  HTML Report: $([ "$GENERATE_HTML" == "true" ] && echo "Enabled" || echo "Disabled")"
    echo "  Verbose: $([ "$VERBOSE" == "true" ] && echo "Enabled" || echo "Disabled")"
    
    if [[ "$GENERATE_COVERAGE" == "true" ]] && [ -f "coverage/lcov.info" ]; then
        echo ""
        print_info "Coverage file generated: coverage/lcov.info"
        
        # Show basic coverage stats if lcov is available
        if command -v lcov &> /dev/null; then
            echo ""
            lcov --summary coverage/lcov.info 2>/dev/null | grep -E "(lines|functions|branches)" | head -3
        fi
    fi
}

# Default values
TEST_TYPE="all"
GENERATE_COVERAGE="false"
GENERATE_HTML="false"
VERBOSE="false"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage)
            GENERATE_COVERAGE="true"
            shift
            ;;
        --html)
            GENERATE_HTML="true"
            GENERATE_COVERAGE="true"  # HTML requires coverage
            shift
            ;;
        --verbose)
            VERBOSE="true"
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        unit|widget|integration|privacy|all)
            TEST_TYPE="$1"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_info "Flutter Test Runner"
    print_info "==================="
    
    check_dependencies
    run_tests "$TEST_TYPE"
    generate_html_coverage
    show_test_summary "$TEST_TYPE"
    
    print_success "Test execution completed!"
}

# Run main function
main