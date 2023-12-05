namespace Microsoft.PowerShell.SHiPS
{

    /// <summary>
    /// Defines a type that represents a leaf node.
    /// </summary>
    public class SHiPSLeaf : SHiPSBase
    {
        /// <summary>
        /// Default C'tor.
        /// </summary>
        public SHiPSLeaf()
        {
        }

        /// <summary>
        /// C'tor.
        /// </summary>
        /// <param name="name">Name of the node.</param>
        public SHiPSLeaf(string name) : base(name, isLeaf:true)
        {
        }

        #region RemoveItem
        public virtual void RemoveItem(string path, bool recurse)
        {
            this.Parent?.RemoveItem(path, recurse);
        }
        
        public virtual object RemoveItemDynamicParameters()
        {
            return this.Parent?.RemoveItemDynamicParameters();
        }   
        #endregion
    }
}
