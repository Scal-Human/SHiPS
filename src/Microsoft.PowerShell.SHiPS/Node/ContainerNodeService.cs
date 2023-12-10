using System.Collections.Generic;
using System.Linq;
using System.Management.Automation.Provider;
using CodeOwls.PowerShell.Paths;
using CodeOwls.PowerShell.Provider.PathNodeProcessors;
using CodeOwls.PowerShell.Provider.PathNodes;


namespace Microsoft.PowerShell.SHiPS
{

    /// <summary>
    /// Defines actions that applies to a ContainerNode.
    /// </summary>
    internal class ContainerNodeService : PathNodeBase,
        ISetItemContent,
        IClearItemContent,
        IInvokeItem,
        INewItem,
        IRemoveItem
    {
        private readonly SHiPSDrive _drive;
        private readonly SHiPSDirectory _container;
        private static readonly string _directory = "+";
        private readonly ContentHelper _contentHelper;

        internal ContainerNodeService(SHiPSDrive drive, object container, SHiPSDirectory parent)
        {
            _drive = drive;
            _container = container as SHiPSDirectory;
            if (_container != null) { _container.Parent = parent; }
            _contentHelper = new ContentHelper(_container, drive);

        }

        internal SHiPSDirectory ContainerNode
        {
            get { return _container; }
        }

        /// <summary>
        /// Name of the node
        /// </summary>
        public override string Name
        {
            get { return _container.Name; }
        }

        public override IPathValue GetNodeValue()
        {
            return (!_container.IsLeaf)
                ? (IPathValue) new ContainerPathValue(_container, Name)
                : new LeafPathValue(_container, Name);
        }

        public override string ItemMode
        {
            get
            {
                return _directory;
            }
        }

        /// <summary>
        /// GetChildItemDynamicParameters
        /// </summary>
        public override object GetNodeChildrenParameters
        {
            get { return GetDynamicParameters(Constants.GetChildItemDynamicParameters); }
        }

        private  object GetDynamicParameters(string functionName)
        {
            var item = this.ContainerNode;
            if (item == null)
            {
                return null;
            }
            var script = Constants.ScriptBlockWithParam1.StringFormat(functionName);
            var parameters = PSScriptRunner.InvokeScriptBlock(null, item, _drive, script, PSScriptRunner.ReportErrors);
            return parameters?.FirstOrDefault();
        }

        /// <summary>
        /// Usage: dir
        ///        Also gets called by GetChildItem(), GetChildItems, GetItem()
        /// </summary>
        /// <param name="context"></param>
        /// <returns></returns>
        public override IEnumerable<IPathNode> GetNodeChildren(IProviderContext context)
        {
            if (context.Stopping)
            {
                return null;
            }

            return GetNodeChildrenInternal(context);
        }

        private IEnumerable<IPathNode> GetNodeChildrenInternal(IProviderContext context)
        {
            //find the current parent node
            var item = this.ContainerNode;
            if (item == null || item.IsLeaf)
            {
                // WriteChildItem()/P2F can call us while 'dir -recurse' even if the node is set to leaflet.
                yield break;
            }

            // Set the ProviderContext as the DynamicParameters and Filter objects will be used in the
            // PowerShell module's GetChildItem().
            // If dynamic parameters are used, then SHiPS is not using cache.
            // ProviderContext has to be set right now because context.NeedRefresh uses it.
            item.SHiPSProviderContext.Set(context);

            // The item is the parent node from where we can find its child node list.
            // We will find child nodes from the cache if GetChildItem() has been called already and NeedRefresh is false.
            // Otherwise, we will execute the scriptblock and then add the returned nodes to item's child list
            if (item.UseCache && item.ItemNavigated && !context.NeedRefresh(item, _drive))
            {
                var list = item.Children.Values.SelectMany(each => each);

                foreach (var node in list)
                {
                    // Making sure to obey the StopProcessing.
                    if (context.Stopping)
                    {
                        yield break;
                    }
                    yield return node;
                }
            }
            else
            {
                var script = Constants.ScriptBlockWithParam1.StringFormat(Constants.GetChildItem);
                var nodes = PSScriptRunner.InvokeScriptBlockAndBuildTree(context, item, _drive, script, PSScriptRunner.ReportErrors)?.ToList();

                // Save the info of the node just visisted
                SHiPSProvider.LastVisisted.Set(context.Path, this, nodes);

                if (nodes == null || nodes.Count == 0)
                {
                    yield break;
                }

                foreach (var node in nodes)
                {
                    // Making sure to obey the StopProcessing.
                    if (context.Stopping)
                    {
                        yield break;
                    }
                    yield return node;
                }
            }
        }

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
            var item = this.ContainerNode;
            item.SHiPSProviderContext.Set(context);
            var script = Constants.ScriptBlockWithParam2.StringFormat(Constants.InvokeItem);
            var items = PSScriptRunner.InvokeScriptBlock(context, item, _drive, script, PSScriptRunner.ReportErrors, path)?.ToList();
            return items;
        }
        #endregion

        #region INewItem
        public IEnumerable<string> NewItemTypeNames
        {
            get { return (IEnumerable<string>)GetDynamicParameters(Constants.NewItemTypeNames); }
        }
        public object NewItemParameters
        {
            get { return GetDynamicParameters(Constants.NewItemDynamicParameters); }
        }
        public IPathValue NewItem(IProviderContext context, string path, string itemTypeName, object newItemValue)
        {
            var item = this.ContainerNode;
            item.SHiPSProviderContext.Set(context);
            var script = Constants.ScriptBlockWithParam3.StringFormat(Constants.NewItem);
            var nodes = PSScriptRunner.InvokeScriptBlock(context, item, _drive, script, PSScriptRunner.ReportErrors,
                path, itemTypeName
            )?.ToList();
            if (nodes == null || nodes.Count == 0)
            {
                return null;
            }
            return new PathValue(nodes[0], ((SHiPSBase)nodes[0]).Name, ! ((SHiPSBase)nodes[0]).IsLeaf);
        }
        #endregion

        #region IRemoveItem
        public object RemoveItemParameters {
            get {
                return GetDynamicParameters(Constants.RemoveItemDynamicParameters);
            }
        }        
        public void RemoveItem(IProviderContext context, string path, bool recurse) {
            var item = this.ContainerNode.Parent;
            item.SHiPSProviderContext.Set(context);
            var script = Constants.ScriptBlockWithParam2.StringFormat(Constants.RemoveItem);
            PSScriptRunner.InvokeScriptBlock(context, item, _drive, script, PSScriptRunner.ReportErrors, path);
        }
        #endregion

    }
}
