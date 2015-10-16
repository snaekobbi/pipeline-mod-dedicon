package nl.dedicon.pipeline.braille.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.net.URI;
import javax.xml.namespace.QName;

import com.google.common.base.Objects;
import com.google.common.base.Optional;
import com.google.common.collect.ImmutableMap;

import static org.daisy.pipeline.braille.css.Query.parseQuery;
import static org.daisy.pipeline.braille.common.util.Tuple3;
import static org.daisy.pipeline.braille.common.util.URIs.asURI;
import org.daisy.pipeline.braille.common.AbstractTransform;
import org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Function;
import org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Iterables;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Iterables.concat;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.Iterables.transform;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.logCreate;
import static org.daisy.pipeline.braille.common.AbstractTransform.Provider.util.logSelect;
import org.daisy.pipeline.braille.common.CSSBlockTransform;
import org.daisy.pipeline.braille.common.Hyphenator;
import org.daisy.pipeline.braille.common.TextTransform;
import org.daisy.pipeline.braille.common.Transform;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.dispatch;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.memoize;
import static org.daisy.pipeline.braille.common.util.Locales.parseLocale;
import org.daisy.pipeline.braille.common.XProcTransform;
import org.daisy.pipeline.braille.liblouis.LiblouisTranslator;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;
import org.osgi.service.component.ComponentContext;

public interface DediconCSSBlockTransform extends CSSBlockTransform, XProcTransform {
	
	@Component(
		name = "nl.dedicon.pipeline.braille.impl.DediconCSSBlockTransform.Provider",
		service = {
			XProcTransform.Provider.class,
			CSSBlockTransform.Provider.class
		}
	)
	public class Provider extends AbstractTransform.Provider<DediconCSSBlockTransform>
		                  implements XProcTransform.Provider<DediconCSSBlockTransform>, CSSBlockTransform.Provider<DediconCSSBlockTransform> {
		
		private URI href;
		
		@Activate
		private void activate(ComponentContext context, final Map<?,?> properties) {
			href = asURI(context.getBundleContext().getBundle().getEntry("xml/block-translate.xpl"));
		}
		
		private final static String liblouisTable = "(liblouis-table:'" +
			"http://www.dedicon.nl/liblouis/nl-NL-g0.utb,http://www.dedicon.nl/liblouis/undefined.utb')";
		private final static String hyphenationTable = "(libhyphen-table:'http://www.libreoffice.org/dictionaries/hyphen/hyph_nl_NL.dic')";
		private final static String fallbackHyphenationTable = "(hyphenator:tex)(locale:nl-NL)";
		
		private final static Iterable<DediconCSSBlockTransform> empty
		= Iterables.<DediconCSSBlockTransform>empty();
		
		/**
		 * Recognized features:
		 *
		 * - translator: Will only match if the value is `dedicon'.
		 * - locale: Will only match if the language subtag is 'nl'.
		 *
		 */
		protected final Iterable<DediconCSSBlockTransform> _get(String query) {
			Map<String,Optional<String>> q = new HashMap<String,Optional<String>>(parseQuery(query));
			Optional<String> o;
			if ((o = q.remove("locale")) != null)
				if (!"nl".equals(parseLocale(o.get()).getLanguage()))
					return empty;
			if ((o = q.remove("translator")) != null)
				if (o.get().equals("dedicon"))
					if (q.size() == 0) {
						Iterable<Hyphenator> hyphenators = concat(
							logSelect(hyphenationTable, hyphenatorProvider),
							logSelect(fallbackHyphenationTable, hyphenatorProvider));
						return concat(
							transform(
								concat(
									concat(
										transform(
											hyphenators,
											new Function<Hyphenator,String>() {
												public String _apply(Hyphenator h) {
													return h.getIdentifier(); }}),
										"liblouis"),
									"none"),
								new Function<String,Iterable<DediconCSSBlockTransform>>() {
									public Iterable<DediconCSSBlockTransform> _apply(String hyphenator) {
										final String translatorQuery = liblouisTable + "(hyphenator:" + hyphenator + ")";
										return transform(
											logSelect(translatorQuery, liblouisTranslatorProvider),
											new Function<LiblouisTranslator,DediconCSSBlockTransform>() {
												public DediconCSSBlockTransform _apply(LiblouisTranslator translator) {
													return __apply(logCreate(new TransformImpl(translatorQuery, translator))); }}); }})); }
				return empty;
		}
		
		private class TransformImpl extends AbstractTransform implements DediconCSSBlockTransform {
			
			private final LiblouisTranslator translator;
			private final Tuple3<URI,QName,Map<String,String>> xproc;
			
			private TransformImpl(String translatorQuery, LiblouisTranslator translator) {
				Map<String,String> options = ImmutableMap.of("query", translatorQuery);
				xproc = new Tuple3<URI,QName,Map<String,String>>(href, null, options);
				this.translator = translator;
			}
			
			public TextTransform asTextTransform() {
				return translator;
			}
			
			public Tuple3<URI,QName,Map<String,String>> asXProc() {
				return xproc;
			}
			
			@Override
			public String toString() {
				return Objects.toStringHelper(DediconCSSBlockTransform.class.getSimpleName())
					.toString();
			}
		}
		
		@Reference(
			name = "LiblouisTranslatorProvider",
			unbind = "unbindLiblouisTranslatorProvider",
			service = LiblouisTranslator.Provider.class,
			cardinality = ReferenceCardinality.MULTIPLE,
			policy = ReferencePolicy.DYNAMIC
		)
		protected void bindLiblouisTranslatorProvider(LiblouisTranslator.Provider provider) {
			liblouisTranslatorProviders.add(provider);
		}
	
		protected void unbindLiblouisTranslatorProvider(LiblouisTranslator.Provider provider) {
			liblouisTranslatorProviders.remove(provider);
			liblouisTranslatorProvider.invalidateCache();
		}
	
		private List<Transform.Provider<LiblouisTranslator>> liblouisTranslatorProviders
		= new ArrayList<Transform.Provider<LiblouisTranslator>>();
		private Transform.Provider.MemoizingProvider<LiblouisTranslator> liblouisTranslatorProvider
		= memoize(dispatch(liblouisTranslatorProviders));
		
		@Reference(
			name = "HyphenatorProvider",
			unbind = "unbindHyphenatorProvider",
			service = Hyphenator.Provider.class,
			cardinality = ReferenceCardinality.MULTIPLE,
			policy = ReferencePolicy.DYNAMIC
		)
		@SuppressWarnings(
			"unchecked" // safe cast to Transform.Provider<Hyphenator>
		)
		protected void bindHyphenatorProvider(Hyphenator.Provider<?> provider) {
			hyphenatorProviders.add((Transform.Provider<Hyphenator>)provider);
		}
	
		protected void unbindHyphenatorProvider(Hyphenator.Provider<?> provider) {
			hyphenatorProviders.remove(provider);
			hyphenatorProvider.invalidateCache();
		}
	
		private List<Transform.Provider<Hyphenator>> hyphenatorProviders
		= new ArrayList<Transform.Provider<Hyphenator>>();
		private Transform.Provider.MemoizingProvider<Hyphenator> hyphenatorProvider
		= memoize(dispatch(hyphenatorProviders));
		
	}
}
