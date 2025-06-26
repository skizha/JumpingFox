using JumpingFox.Models;

namespace JumpingFox.Services
{
    public interface IMetricsService
    {
        void RecordRequest(string endpoint);
        MetricsResponse GetMetrics();
        void Reset();
    }

    public class MetricsService : IMetricsService
    {
        private int _totalRequests = 0;
        private DateTime _lastRequestTime = DateTime.UtcNow;
        private readonly Dictionary<string, int> _endpointCalls = new();
        private readonly object _lock = new();

        public void RecordRequest(string endpoint)
        {
            lock (_lock)
            {
                _totalRequests++;
                _lastRequestTime = DateTime.UtcNow;
                
                if (_endpointCalls.ContainsKey(endpoint))
                    _endpointCalls[endpoint]++;
                else
                    _endpointCalls[endpoint] = 1;
            }
        }

        public MetricsResponse GetMetrics()
        {
            lock (_lock)
            {
                return new MetricsResponse
                {
                    TotalRequests = _totalRequests,
                    LastRequestTime = _lastRequestTime,
                    EndpointCalls = new Dictionary<string, int>(_endpointCalls)
                };
            }
        }

        public void Reset()
        {
            lock (_lock)
            {
                _totalRequests = 0;
                _lastRequestTime = DateTime.UtcNow;
                _endpointCalls.Clear();
            }
        }
    }
}
