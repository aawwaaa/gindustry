using Godot;
using System.Collections.Generic;
using System;
using Gindustry.Content;

namespace Gindustry;

public partial class Vars
{
    public partial class Vars_Contents : Node
    {
        [Signal]
        public delegate void ContentRegistedEventHandler(Content.Content content);
        private Dictionary<string, List<Action<Content.Content>>> contentCallbacks = new ();

        private Log.Logger logger = Log.RegisterLogger("Contents");

        private List<Content.Content> contents = new ();
        private Dictionary<string, Content.Content> contentsMapping = new ();
        private Dictionary<Type.ContentType, Dictionary<string, Content.Content>> contentsMappingBasedType = new ();
        private Dictionary<Type.ContentCategory, Dictionary<Type.ContentType, Dictionary<string, Content.Content>>> contentsMappingBasedCategory = new ();

        public Content.Content RegisterContent(Content.Content content)
        {
            content.Source = Vars.Mods.CurrentLoadingMod;
            content._Data();
            Vars_Objects.AddObjectType(content);
            contents.Add(content);
            content.Source.Contents.Add(content);
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

        public List<Content.Content> GetContents(Type.ContentType type)
        {
            return new List<Content.Content>(contentsMappingBasedType[type].Values);
        }

        public List<Content.Content> GetContentsByCategory(Type.ContentCategory category, Type.ContentType type)
        {
            return new List<Content.Content>(contentsMappingBasedCategory[category][type].Values);
        }

        public Content.Content GetContentByFullId(string fullId)
        {
            return contentsMapping.ContainsKey(fullId) ? contentsMapping[fullId] : null;
        }

        public Content.Content GetContentByIndex(uint index)
        {
            return Vars.Objects.GetObjectTypeByIndex(index) as Content.Content;
        }

        public void GetContentCallback(string fullId, Action<Content.Content> callback)
        {
            if (contentsMapping.ContainsKey(fullId))
                callback(contentsMapping[fullId]);
            else
                contentCallbacks[fullId].Add(callback);
        }
    }
}
