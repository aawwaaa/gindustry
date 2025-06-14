using Godot;
using System.Collections.Generic;
using System;

public partial class Vars
{
    public partial class Vars_Contents : Node
    {
        [Signal]
        public delegate void ContentRegistedEventHandler(Content content);
        private Dictionary<string, List<Action<Content>>> contentCallbacks = new ();

        private Log.Logger logger = Log.RegisterLogger("Contents");

        private List<Content> contents = new ();
        private Dictionary<string, Content> contentsMapping = new ();
        private Dictionary<ContentType, Dictionary<string, Content>> contentsMappingBasedType = new ();
        private Dictionary<ContentCategory, Dictionary<ContentType, Dictionary<string, Content>>> contentsMappingBasedCategory = new ();

        public Content RegisterContent(Content content)
        {
            content.Mod = Vars.Mods.CurrentLoadingMod;
            content._Data();
            Vars_Objects.AddObjectType(content);
            contents.Add(content);
            content.Mod.Contents.Add(content);
            string fullId = content.FullId;
            logger.Debug($"Load content: {fullId}");
            contentsMapping[fullId] = content;

            if (!contentsMappingBasedType.ContainsKey(content.Type))
                contentsMappingBasedType[content.Type] = new();
            if (!contentsMappingBasedCategory.ContainsKey(content.Category))
                contentsMappingBasedCategory[content.Category] = new ();
            if (!contentsMappingBasedCategory[content.Category].ContainsKey(content.Type))
                contentsMappingBasedCategory[content.Category][content.Type] = new ();

            contentsMappingBasedType[content.Type][fullId] = content;
            contentsMappingBasedCategory[content.Category][content.Type][fullId] = content;

            content.ContentRegisted();
            content._Assign();

            EmitSignal(SignalName.ContentRegisted, content);
            if (contentCallbacks.ContainsKey(fullId))
                foreach(var callback in contentCallbacks[fullId])
                    callback(content);
            contentCallbacks.Remove(fullId);
            return content;
        }

        public List<Content> GetContents(ContentType type)
        {
            return new List<Content>(contentsMappingBasedType[type].Values);
        }

        public List<Content> GetContentsByCategory(ContentCategory category, ContentType type)
        {
            return new List<Content>(contentsMappingBasedCategory[category][type].Values);
        }

        public Content GetContentByFullId(string fullId)
        {
            return contentsMapping.ContainsKey(fullId) ? contentsMapping[fullId] : null;
        }

        public Content GetContentByIndex(uint index)
        {
            return Vars.Objects.GetObjectTypeByIndex(index) as Content;
        }

        public void GetContentCallback(string fullId, Action<Content> callback)
        {
            if (contentsMapping.ContainsKey(fullId))
                callback(contentsMapping[fullId]);
            else
                contentCallbacks[fullId].Add(callback);
        }
    }
}
