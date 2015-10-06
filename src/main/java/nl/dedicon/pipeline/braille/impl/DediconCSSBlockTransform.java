package nl.dedicon.pipeline.braille.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.NoSuchElementException;
import java.net.URI;
import javax.xml.namespace.QName;

import static com.google.common.base.Objects.toStringHelper;
import com.google.common.base.Optional;
import com.google.common.collect.ImmutableMap;
import static com.google.common.collect.Iterables.concat;
import static com.google.common.collect.Iterables.transform;
import static com.google.common.collect.Lists.newArrayList;

import static org.daisy.pipeline.braille.css.Query.parseQuery;
import static org.daisy.pipeline.braille.common.util.Tuple3;
import static org.daisy.pipeline.braille.common.util.URIs.asURI;
import org.daisy.pipeline.braille.common.CSSBlockTransform;
import org.daisy.pipeline.braille.common.Hyphenator;
import org.daisy.pipeline.braille.common.Transform;
import org.daisy.pipeline.braille.common.Transform.AbstractTransform;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.dispatch;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.logCreate;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.logSelect;
import static org.daisy.pipeline.braille.common.Transform.Provider.util.memoize;
import static org.daisy.pipeline.braille.common.util.Locales.parseLocale;
import org.daisy.pipeline.braille.common.WithSideEffect;
import org.daisy.pipeline.braille.common.XProcTransform;
import org.daisy.pipeline.braille.liblouis.LiblouisTranslator;

import org.osgi.service.component.annotations.Activate;
import org.osgi.service.component.annotations.Component;
import org.osgi.service.component.annotations.Reference;
import org.osgi.service.component.annotations.ReferenceCardinality;
import org.osgi.service.component.annotations.ReferencePolicy;
import org.osgi.service.component.ComponentContext;

import org.slf4j.Logger;

public interface DediconCSSBlockTransform extends CSSBlockTransform, XProcTransform {
	
	@Component(
		name = "nl.dedicon.pipeline.braille.impl.DediconCSSBlockTransform.Provider",
		service = {
			XProcTransform.Provider.class,
			CSSBlockTransform.Provider.class
		}
	)
	public class Provider implements XProcTransform.Provider<DediconCSSBlockTransform>, CSSBlockTransform.Provider<DediconCSSBlockTransform> {
		
		private URI href;
		
		@Activate
		private void activate(ComponentContext context, final Map<?,?> properties) {
			href = asURI(context.getBundleContext().getBundle().getEntry("xml/block-translate.xpl"));
		}
		
		/**
		 * Recognized features:
		 *
		 * - translator: Will only match if the value is `dedicon'.
		 * - locale: Will only match if the language subtag is 'nl'.
		 *
		 */
		public Iterable<DediconCSSBlockTransform> get(String query) {
			 return impl.get(query);
		 }
	
		public Transform.Provider<DediconCSSBlockTransform> withContext(Logger context) {
			return impl.withContext(context);
		}
	
		private Transform.Provider.MemoizingProvider<DediconCSSBlockTransform> impl = new ProviderImpl(null);
	
		private class ProviderImpl extends AbstractProvider<DediconCSSBlockTransform> {
			
			private final static String liblouisTable = "(liblouis-table:'" +
				"http://www.dedicon.nl/liblouis/nl-NL-g0.utb,http://www.dedicon.nl/liblouis/undefined.utb')";
			private final static String hyphenationTable = "(libhyphen-table:'http://www.libreoffice.org/dictionaries/hyphen/hyph_nl_NL.dic')";
			private final static String fallbackHyphenationTable = "(hyphenator:tex)(locale:nl-NL)";
		
			private ProviderImpl(Logger context) {
				super(context);
			}
		
			protected Transform.Provider.MemoizingProvider<DediconCSSBlockTransform> _withContext(Logger context) {
				return new ProviderImpl(context);
			}
		
			protected final Iterable<WithSideEffect<DediconCSSBlockTransform,Logger>> __get(String query) {
				Map<String,Optional<String>> q = new HashMap<String,Optional<String>>(parseQuery(query));
				Optional<String> o;
				if ((o = q.remove("locale")) != null)
					if (!"nl".equals(parseLocale(o.get()).getLanguage()))
						return empty;
				if ((o = q.remove("translator")) != null)
					if (o.get().equals("dedicon"))
						if (q.size() == 0) {
							Iterable<WithSideEffect<Hyphenator,Logger>> hyphenators = concat(
								logSelect(hyphenationTable, hyphenatorProvider.get(hyphenationTable)),
								logSelect(fallbackHyphenationTable, hyphenatorProvider.get(fallbackHyphenationTable)));
							return transform(
								concat(
									transform(
										hyphenators,
										new WithSideEffect.Function<Hyphenator,String,Logger>() {
											public String _apply(Hyphenator h) {
												return h.getIdentifier(); }}),
									newArrayList(
										WithSideEffect.<String,Logger>of("liblouis"),
										WithSideEffect.<String,Logger>of("none"))),
								new WithSideEffect.Function<String,DediconCSSBlockTransform,Logger>() {
									public DediconCSSBlockTransform _apply(String hyphenator) {
										String translatorQuery = liblouisTable + "(hyphenator:" + hyphenator + ")";
										try {
											applyWithSideEffect(
												logSelect(
													translatorQuery,
													liblouisTranslatorProvider.get(translatorQuery)).iterator().next()); }
										catch (NoSuchElementException e) {
											throw new NoSuchElementException(); }
										return applyWithSideEffect(
											logCreate(
												(DediconCSSBlockTransform)new TransformImpl(translatorQuery))); }}); }
				return empty;
			}
		}
	
		private final static Iterable<WithSideEffect<DediconCSSBlockTransform,Logger>> empty
		= Optional.<WithSideEffect<DediconCSSBlockTransform,Logger>>absent().asSet();
		
		private class TransformImpl extends AbstractTransform implements DediconCSSBlockTransform {
			
			private final Tuple3<URI,QName,Map<String,String>> xproc;
			
			private TransformImpl(String translatorQuery) {
				Map<String,String> options = ImmutableMap.of("query", translatorQuery);
				xproc = new Tuple3<URI,QName,Map<String,String>>(href, null, options);
			}
	
			public Tuple3<URI,QName,Map<String,String>> asXProc() {
				return xproc;
			}
	
			@Override
			public String toString() {
				return toStringHelper(DediconCSSBlockTransform.class.getSimpleName())
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
		protected void bindHyphenatorProvider(Hyphenator.Provider provider) {
			hyphenatorProviders.add(provider);
		}
	
		protected void unbindHyphenatorProvider(Hyphenator.Provider provider) {
			hyphenatorProviders.remove(provider);
			hyphenatorProvider.invalidateCache();
		}
	
		private List<Transform.Provider<Hyphenator>> hyphenatorProviders
		= new ArrayList<Transform.Provider<Hyphenator>>();
		private Transform.Provider.MemoizingProvider<Hyphenator> hyphenatorProvider
		= memoize(dispatch(hyphenatorProviders));
		
	}
}
