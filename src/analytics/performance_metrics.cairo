// Performance Metrics module for Veritas
#[starknet::interface]
pub trait IPerformanceMetrics<T> {
    fn record_metric(ref self: T, metric_type: u32, value: u32);
    fn get_average_metric(self: @T, metric_type: u32, period: u64) -> u32;
    fn get_metrics_summary(self: @T) -> Array<felt252>;
    fn get_trend(self: @T, metric_type: u32) -> felt252;
}

#[starknet::contract]
pub mod PerformanceMetrics {
    use super::IPerformanceMetrics;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

    #[storage]
    struct Storage {
        metrics: Map<(u32, u64), u32>, // (metric_type, timestamp) -> value
        metric_counts: Map<u32, u32>, // metric_type -> count
        metric_sums: Map<u32, u32>, // metric_type -> total sum
        last_update: u64,
        admin: felt252,
        total_metrics: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: felt252) {
        self.admin.write(admin);
        self.last_update.write(starknet::get_block_timestamp());
        self.total_metrics.write(0);
    }

    #[abi(embed_v0)]
    impl PerformanceMetricsImpl of IPerformanceMetrics<ContractState> {
        fn record_metric(ref self: ContractState, metric_type: u32, value: u32) {
            let timestamp = starknet::get_block_timestamp();
            
            // Store metric with timestamp
            self.metrics.write((metric_type, timestamp), value);
            
            // Update aggregates
            let current_count = self.metric_counts.read(metric_type);
            let current_sum = self.metric_sums.read(metric_type);
            
            self.metric_counts.write(metric_type, current_count + 1);
            self.metric_sums.write(metric_type, current_sum + value);
            
            self.last_update.write(timestamp);
            self.total_metrics.write(self.total_metrics.read() + 1);
        }

        fn get_average_metric(self: @ContractState, metric_type: u32, period: u64) -> u32 {
            let current_time = starknet::get_block_timestamp();
            let start_time = current_time - period;
            
            let mut sum = 0;
            let mut count = 0;
            
            // Simplified - in practice, would iterate through relevant metrics
            let total_sum = self.metric_sums.read(metric_type);
            let total_count = self.metric_counts.read(metric_type);
            
            if total_count > 0 {
                total_sum / total_count
            } else {
                0
            }
        }

        fn get_metrics_summary(self: @ContractState) -> Array<felt252> {
            array![
                self.total_metrics.read().into(),
                self.last_update.read().into(),
                self.metric_counts.read(0).into(), // metric type 0 count
                self.metric_sums.read(0).into(), // metric type 0 sum
                'active'
            ]
        }

        fn get_trend(self: @ContractState, metric_type: u32) -> felt252 {
            let count = self.metric_counts.read(metric_type);
            let sum = self.metric_sums.read(metric_type);
            
            if count == 0 {
                return 'no_data';
            }
            
            let average = sum / count;
            
            // Simple trend analysis
            if average > 80 {
                'excellent'
            } else if average > 60 {
                'good'
            } else if average > 40 {
                'average'
            } else {
                'poor'
            }
        }
    }
}
