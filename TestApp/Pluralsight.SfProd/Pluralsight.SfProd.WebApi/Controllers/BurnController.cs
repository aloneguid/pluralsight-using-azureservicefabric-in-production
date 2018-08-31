using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using LogMagic;
using Microsoft.AspNetCore.Mvc;
using Microsoft.ServiceFabric.Services.Client;
using Microsoft.ServiceFabric.Services.Remoting.Client;
using Microsoft.ServiceFabric.Services.Remoting.V2.FabricTransport.Client;
using Pluralsight.SfProd.Contracts;

namespace Pluralsight.SfProd.WebApi.Controllers
{
    [Route("api/[controller]")]
    public class BurnController : Controller
    {
        private static readonly ILog log = L.G(typeof(BurnController));
    
        const int partitionCount = 10;

        private ICpuBurnerService GetBurner(long partition)
        {
            var proxyFactory = new ServiceProxyFactory(c => new FabricTransportServiceRemotingClientFactory());
            return proxyFactory.CreateServiceProxy<ICpuBurnerService>(
                new Uri("fabric:/Pluralsight.SfProd/Pluralsight.SfProd.CpuBurner"),
                new ServicePartitionKey(partition));
        }


        // GET api/burn
        [HttpGet]
        public async Task<int[]> Get()
        {
            var result = new List<int>();

            using (var time = new TimeMeasure())
            {
                for (int i = 0; i < partitionCount; i++)
                {
                    int tps = await GetBurner(i).GetTransactionsPerSecondAsync();

                    result.Add(tps);
                }

                log.Request("Get Burn Count", time.ElapsedTicks);
            }

            return result.ToArray();
        }


        // POST api/burn
        [HttpPost]
        public async Task Post(int tps)
        {
            using (var time = new TimeMeasure())
            {

                for (int i = 0; i < partitionCount; i++)
                {
                    var partition = GetBurner(i);
                    await partition.SetTransactionsPerSecondAsync(tps);
                }

                log.Request("Set Burn Count", time.ElapsedTicks);
            }
        }
    }
}
