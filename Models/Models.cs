namespace JumpingFox.Models
{
    public class Fox
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Color { get; set; } = string.Empty;
        public int JumpHeight { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsActive { get; set; }
    }

    public class JumpRecord
    {
        public int Id { get; set; }
        public int FoxId { get; set; }
        public int Height { get; set; }
        public DateTime JumpTime { get; set; }
        public string Location { get; set; } = string.Empty;
    }

    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public T? Data { get; set; }
        public string Message { get; set; } = string.Empty;
        public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    }

    public class RateLimitTestRequest
    {
        public string ClientId { get; set; } = string.Empty;
        public int RequestCount { get; set; }
        public string TestType { get; set; } = string.Empty;
    }

    public class MetricsResponse
    {
        public int TotalRequests { get; set; }
        public int TotalFoxes { get; set; }
        public int TotalJumps { get; set; }
        public DateTime LastRequestTime { get; set; }
        public Dictionary<string, int> EndpointCalls { get; set; } = new();
    }
}
