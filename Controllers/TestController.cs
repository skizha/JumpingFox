using Microsoft.AspNetCore.Mvc;
using JumpingFox.Models;
using JumpingFox.Services;

namespace JumpingFox.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TestController : ControllerBase
    {
        private readonly IMetricsService _metricsService;
        private readonly IDataService _dataService;
        private readonly ILogger<TestController> _logger;

        public TestController(IMetricsService metricsService, IDataService dataService, ILogger<TestController> logger)
        {
            _metricsService = metricsService;
            _dataService = dataService;
            _logger = logger;
        }

        /// <summary>
        /// Fast endpoint - Good for testing high-frequency rate limits
        /// </summary>
        [HttpGet("fast")]
        public IActionResult FastEndpoint()
        {
            _metricsService.RecordRequest("GET /api/test/fast");
            _logger.LogInformation("Fast endpoint called");

            return Ok(new ApiResponse<object>
            {
                Success = true,
                Data = new { 
                    Message = "Fast response", 
                    Timestamp = DateTime.UtcNow,
                    ProcessingTime = "~5ms"
                },
                Message = "Fast endpoint executed successfully"
            });
        }

        /// <summary>
        /// Slow endpoint - Good for testing rate limits with processing delays
        /// </summary>
        [HttpGet("slow")]
        public async Task<IActionResult> SlowEndpoint()
        {
            _metricsService.RecordRequest("GET /api/test/slow");
            _logger.LogInformation("Slow endpoint called");

            // Simulate slow processing
            await Task.Delay(2000);

            return Ok(new ApiResponse<object>
            {
                Success = true,
                Data = new { 
                    Message = "Slow response after processing", 
                    Timestamp = DateTime.UtcNow,
                    ProcessingTime = "~2000ms"
                },
                Message = "Slow endpoint executed successfully"
            });
        }

        /// <summary>
        /// Memory intensive endpoint - Good for testing resource-based rate limits
        /// </summary>
        [HttpGet("memory-intensive")]
        public IActionResult MemoryIntensive()
        {
            _metricsService.RecordRequest("GET /api/test/memory-intensive");
            _logger.LogInformation("Memory intensive endpoint called");

            // Create some memory pressure
            var largeData = new List<string>();
            for (int i = 0; i < 10000; i++)
            {
                largeData.Add($"Data item {i} with some additional text to consume memory");
            }

            var result = new
            {
                Message = "Memory intensive operation completed",
                ItemsProcessed = largeData.Count,
                Timestamp = DateTime.UtcNow,
                MemoryUsage = GC.GetTotalMemory(false)
            };

            // Clear the data
            largeData.Clear();
            GC.Collect();

            return Ok(new ApiResponse<object>
            {
                Success = true,
                Data = result,
                Message = "Memory intensive endpoint executed successfully"
            });
        }

        /// <summary>
        /// Batch operation endpoint - Good for testing bulk operation rate limits
        /// </summary>
        [HttpPost("batch")]
        public async Task<IActionResult> BatchOperation([FromBody] RateLimitTestRequest request)
        {
            _metricsService.RecordRequest("POST /api/test/batch");
            _logger.LogInformation("Batch operation called for client: {ClientId}", request.ClientId);

            var results = new List<object>();
            
            for (int i = 0; i < Math.Min(request.RequestCount, 50); i++)
            {
                await Task.Delay(10); // Small delay per operation
                results.Add(new
                {
                    OperationId = i + 1,
                    ClientId = request.ClientId,
                    Status = "Completed",
                    Timestamp = DateTime.UtcNow
                });
            }

            return Ok(new ApiResponse<object>
            {
                Success = true,
                Data = new
                {
                    ProcessedOperations = results.Count,
                    RequestedOperations = request.RequestCount,
                    TestType = request.TestType,
                    Results = results
                },
                Message = $"Batch operation completed for {request.ClientId}"
            });
        }

        /// <summary>
        /// Error simulation endpoint - Good for testing how rate limits handle errors
        /// </summary>
        [HttpGet("error/{errorType}")]
        public IActionResult SimulateError(string errorType)
        {
            _metricsService.RecordRequest($"GET /api/test/error/{errorType}");
            _logger.LogInformation("Error simulation endpoint called: {ErrorType}", errorType);

            return errorType.ToLower() switch
            {
                "400" or "badrequest" => BadRequest(new ApiResponse<object>
                {
                    Success = false,
                    Message = "Simulated bad request error"
                }),
                "401" or "unauthorized" => Unauthorized(new ApiResponse<object>
                {
                    Success = false,
                    Message = "Simulated unauthorized error"
                }),
                "403" or "forbidden" => Forbid(),
                "404" or "notfound" => NotFound(new ApiResponse<object>
                {
                    Success = false,
                    Message = "Simulated not found error"
                }),
                "429" or "ratelimit" => StatusCode(429, new ApiResponse<object>
                {
                    Success = false,
                    Message = "Simulated rate limit exceeded error"
                }),
                "500" or "servererror" => StatusCode(500, new ApiResponse<object>
                {
                    Success = false,
                    Message = "Simulated internal server error"
                }),
                _ => Ok(new ApiResponse<object>
                {
                    Success = true,
                    Data = new { ErrorType = errorType, Message = "No error simulated" },
                    Message = "Valid error type not provided"
                })
            };
        }

        /// <summary>
        /// Load test endpoint - Generates multiple internal operations
        /// </summary>
        [HttpPost("load")]
        public async Task<IActionResult> LoadTest([FromQuery] int operations = 10)
        {
            _metricsService.RecordRequest("POST /api/test/load");
            _logger.LogInformation("Load test endpoint called with {Operations} operations", operations);

            operations = Math.Min(operations, 100); // Limit to prevent abuse

            var tasks = new List<Task<object>>();
            
            for (int i = 0; i < operations; i++)
            {
                tasks.Add(SimulateOperation(i));
            }

            var results = await Task.WhenAll(tasks);

            return Ok(new ApiResponse<object>
            {
                Success = true,
                Data = new
                {
                    CompletedOperations = results.Length,
                    RequestedOperations = operations,
                    Results = results
                },
                Message = "Load test completed successfully"
            });
        }

        private async Task<object> SimulateOperation(int operationId)
        {
            // Simulate various operations with different delays
            var random = new Random();
            var delay = random.Next(10, 100);
            await Task.Delay(delay);

            return new
            {
                OperationId = operationId,
                ProcessingTime = delay,
                Timestamp = DateTime.UtcNow,
                Status = "Completed"
            };
        }

        /// <summary>
        /// Get current test metrics - Useful for monitoring rate limit testing
        /// </summary>
        [HttpGet("metrics")]
        public IActionResult GetMetrics()
        {
            _metricsService.RecordRequest("GET /api/test/metrics");
            var metrics = _metricsService.GetMetrics();
            
            return Ok(new ApiResponse<MetricsResponse>
            {
                Success = true,
                Data = metrics,
                Message = "Current metrics retrieved successfully"
            });
        }

        /// <summary>
        /// Reset test metrics - Useful for starting fresh rate limit tests
        /// </summary>
        [HttpPost("metrics/reset")]
        public IActionResult ResetMetrics()
        {
            _metricsService.Reset();
            _logger.LogInformation("Test metrics reset");

            return Ok(new ApiResponse<object>
            {
                Success = true,
                Data = new { Message = "Metrics reset successfully", ResetTime = DateTime.UtcNow },
                Message = "Metrics have been reset"
            });
        }
    }
}
