using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.ServiceFabric.Services.Client;
using Microsoft.ServiceFabric.Services.Remoting.Client;
using Microsoft.ServiceFabric.Services.Remoting.V2.FabricTransport.Client;
using Pluralsight.SfProd.Contracts;

namespace Pluralsight.SfProd.WebApi.Controllers
{
    [Route("api/[controller]")]
    public class ValuesController : Controller
    {
        private ICpuBurnerService GetBurner(long partition)
        {
            var proxyFactory = new ServiceProxyFactory(c => new FabricTransportServiceRemotingClientFactory());
            return proxyFactory.CreateServiceProxy<ICpuBurnerService>(
                new Uri("fabric:/Pluralsight.SfProd/Pluralsight.SfProd.CpuBurner"),
                new ServicePartitionKey(partition));
        }


        // GET api/values
        [HttpGet]
        public async Task<int[]> Get()
        {
            var result = new List<int>();

            for (int i = 0; i < 2; i++)
            {
                int tps = await GetBurner(i).GetTransactionsPerSecondAsync();

                result.Add(tps);
            }

            return result.ToArray();
        }


        // POST api/values
        [HttpPost]
        public async Task Post(int tps)
        {
            for(int i = 0; i < 2; i++)
            {
                var partition = GetBurner(i);
                await partition.SetTransactionsPerSecondAsync(tps);
            }
        }
    }
}
