using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation.Provider;
using CodeOwls.PowerShell.Paths;
using CodeOwls.PowerShell.Provider.PathNodeProcessors;
using CodeOwls.PowerShell.Provider.PathNodes;

namespace Microsoft.PowerShell.SHiPS
{
    /// <summary>
    /// Defines actions that applies to a SHiPSLeaf node.
    /// </summary>
    internal class LeafNodeService : PathNodeBase,
        IGetItemContent,
        ISetItemContent,
        IClearItemContent,
        IInvokeItem,
        IRemoveItem
    {
        private readonly SHiPSLeaf _shipsLeaf;
        private static readonly string _leaf = ".";
        private readonly SHiPSDrive _drive;
        private readonly ContentHelper _contentHelper;

        internal LeafNodeService(object leafObject, SHiPSDrive drive, SHiPSDirectory parent)
        {
            _shipsLeaf = leafObject as SHiPSLeaf;
            _drive = drive;
            _contentHelper = new ContentHelper(_shipsLeaf, drive);
            if (_shipsLeaf != null) { _shipsLeaf.Parent = parent; }
        }

        public override IPathValue GetNodeValue()
        {
            return new LeafPathValue(_shipsLeaf, Name);
        }

        public override string ItemMode
        {
            get {return _leaf; }
        }

        public override string Name
        {
            get { return _shipsLeaf.Name; }
        }

        private  object GetDynamicParameters(string functionName)
        {
            var item = this._shipsLeaf;
            if (item == null)
            {
                return null;
            }
            var script = Constants.ScriptBlockWithParam1.StringFormat(functionName);
            var parameters = PSScriptRunner.InvokeScriptBlock(null, item, _drive, script, PSScriptRunner.ReportErrors);
            return parameters?.FirstOrDefault();
        }

        #region IGetItemContent

        public IContentReader GetContentReader(IProviderContext context)
        {
            return _contentHelper.GetContentReader(context);
        }

        public object GetContentReaderDynamicParameters(IProviderContext context)
        {
            return GetDynamicParameters(Constants.RemoveItemDynamicParameters);
        }

        #endregion

        #region ISetItemContent

        public IContentWriter GetContentWriter(IProviderContext context)
        {
            return _contentHelper.GetContentWriter(context);
        }

        public object GetContentWriterDynamicParameters(IProviderContext context)
        {
            return _contentHelper.GetContentWriterDynamicParameters(context);
        }

        #endregion

        #region IClearItemContent

        public void ClearContent(IProviderContext context)
        {
            // Define ClearContent for now as the PowerShell engine calls ClearContent first for Set-Content cmdlet.
            _contentHelper.ClearContent(context);
        }

        public object ClearContentDynamicParameters(IProviderContext context)
        {
            return _contentHelper.ClearContentDynamicParameters(context);
        }

        #endregion
            
        #region IInvokeItem
        public object InvokeItemParameters {
            get {
                return GetDynamicParameters(Constants.InvokeItemDynamicParameters);
            }
        }        
        public IEnumerable<object> InvokeItem(IProviderContext context, string path) {
            var item = this._shipsLeaf;
            item.SHiPSProviderContext.Set(context);
            var script = Constants.ScriptBlockWithParam2.StringFormat(Constants.InvokeItem);
            var results = PSScriptRunner.InvokeScriptBlock(context, item, _drive, script, PSScriptRunner.ReportErrors, path)?.ToList<object>();
            if (null == results)
            {
                yield break;
            }
            foreach (var result in results)
            {
                // Making sure to obey the StopProcessing.
                if (context.Stopping)
                {
                    yield break;
                }
                yield return result;
            }
        }
        #endregion

        #region IRemoveItem
        public object RemoveItemParameters {
            get {
                return GetDynamicParameters(Constants.RemoveItemDynamicParameters);
            }
        }        
        public void RemoveItem(IProviderContext context, string path, bool recurse) {
            var item = this._shipsLeaf.Parent;
            item.SHiPSProviderContext.Set(context);
            var script = Constants.ScriptBlockWithParam2.StringFormat(Constants.RemoveItem);
            PSScriptRunner.InvokeScriptBlock(context, item, _drive, script, PSScriptRunner.ReportErrors, path);
        }
        #endregion

    }
}
