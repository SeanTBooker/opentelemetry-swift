// Copyright 2020, OpenTelemetry Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import GRPC
import OpenTelemetryApi
import OpenTelemetrySdk

public class OtelpMetricExporter : MetricExporter {
    
    let channel : GRPCChannel
    let metricClient: Opentelemetry_Proto_Collector_Metrics_V1_MetricsServiceClient
    let deadlineMS : Int
    
    public init(channel: GRPCChannel, timeoutMS: Int = 0) {
        self.channel = channel
        self.deadlineMS = timeoutMS
        self.metricClient = Opentelemetry_Proto_Collector_Metrics_V1_MetricsServiceClient(channel: self.channel)
    }
    
    
    public func export(metrics: [Metric], shouldCancel: (() -> Bool)?) -> MetricExporterResultCode {
        let exportRequest = Opentelemetry_Proto_Collector_Metrics_V1_ExportMetricsServiceRequest
            .with {
                $0.resourceMetrics = MetricsAdapter.toProtoResourceMetrics(metricDataList: metrics)
            }
        
        if deadlineMS > 0 {
            metricClient.defaultCallOptions.timeout = try! GRPCTimeout.milliseconds(deadlineMS)
        }
        
        let export = metricClient.export(exportRequest)
        
        
        do {
            _ = try export.response.wait()
            return .success
        } catch {
            return .failureRetryable
        }
    }
    
    public func flush() -> SpanExporterResultCode {
        return .success
    }
    
    public func shutdown() {
       _ = channel.close()
    }
    
    
}
