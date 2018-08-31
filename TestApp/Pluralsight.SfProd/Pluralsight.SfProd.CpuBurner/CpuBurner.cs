using System;
using System.Collections.Generic;
using System.Fabric;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.ServiceFabric.Data.Collections;
using Microsoft.ServiceFabric.Services.Communication.Runtime;
using Microsoft.ServiceFabric.Services.Runtime;
using Microsoft.ServiceFabric.Services.Remoting;
using Microsoft.ServiceFabric.Services.Remoting.Runtime;
using Pluralsight.SfProd.Contracts;
using Microsoft.ServiceFabric.Services.Remoting.V2.FabricTransport.Runtime;
using Microsoft.ServiceFabric.Data;
using LogMagic;

namespace Pluralsight.SfProd.CpuBurner
{
    /// <summary>
    /// An instance of this class is created for each service replica by the Service Fabric runtime.
    /// </summary>
    internal sealed class CpuBurner : StatefulService, ICpuBurnerService
    {
        private static readonly ILog log = L.G(typeof(CpuBurner));

        public CpuBurner(StatefulServiceContext context)
            : base(context)
        {
            L.Config
                .WriteTo.AzureApplicationInsights("8927d012-0e2f-46cc-8d7e-8a6a154bbc3d")
                .CollectPerformanceCounters.PlatformDefault();
        }

        public async Task<int> GetTransactionsPerSecondAsync()
        {
            var state = await this.StateManager.GetOrAddAsync<IReliableDictionary<string, int>>("state");

            using (var tx = this.StateManager.CreateTransaction())
            {
                ConditionalValue<int> tps = await state.TryGetValueAsync(tx, "tps");

                return tps.HasValue ? tps.Value : 100;
            }
        }

        public async Task SetTransactionsPerSecondAsync(int transactionsPerSecond)
        {
            var state = await this.StateManager.GetOrAddAsync<IReliableDictionary<string, int>>("state");

            using (var tx = this.StateManager.CreateTransaction())
            {
                await state.SetAsync(tx, "tps", transactionsPerSecond);

                await tx.CommitAsync();
            }

            log.Event("Burn Count Changed",
                "BurnCount", transactionsPerSecond);
        }

        /// <summary>
        /// Optional override to create listeners (e.g., HTTP, Service Remoting, WCF, etc.) for this service replica to handle client or user requests.
        /// </summary>
        /// <remarks>
        /// For more information on service communication, see https://aka.ms/servicefabricservicecommunication
        /// </remarks>
        /// <returns>A collection of listeners.</returns>
        protected override IEnumerable<ServiceReplicaListener> CreateServiceReplicaListeners()
        {
            return new[]
            {
                new ServiceReplicaListener(ctx => new FabricTransportServiceRemotingListener(ctx, this))
            };
        }

        /// <summary>
        /// This is the main entry point for your service replica.
        /// This method executes when this replica of your service becomes primary and has write status.
        /// </summary>
        /// <param name="cancellationToken">Canceled when Service Fabric needs to shut down this service replica.</param>
        protected override async Task RunAsync(CancellationToken cancellationToken)
        {
            log.Event("Burner Started");

            while (true)
            {
                cancellationToken.ThrowIfCancellationRequested();

                int tps = await GetTransactionsPerSecondAsync();

                int counter = 0;
                for(int i = 0; i < tps; i++)
                {
                    counter += 1;
                }

                log.Trace("burned {0} cycles", tps);

                await Task.Delay(TimeSpan.FromSeconds(1), cancellationToken);
            }
        }
    }
}
