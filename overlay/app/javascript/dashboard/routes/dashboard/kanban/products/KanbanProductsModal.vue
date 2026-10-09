<script setup>
import { onMounted, reactive, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import KanbanProductSourcesAPI from 'dashboard/api/kanbanProductSources';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close']);
const { t } = useI18n();

const isLoading = ref(false);
const isSyncing = ref({});
const isSubmitting = ref(false);
const activeTab = ref('xml'); // 'xml' | 'csv'
const sources = ref([]);

const xmlForm = reactive({
  name: '',
  feed_url: '',
});

const csvForm = reactive({
  name: '',
  file: null,
});

const fileInputRef = ref(null);

const fetchSources = async () => {
  isLoading.value = true;
  try {
    const response = await KanbanProductSourcesAPI.getSources();
    sources.value = response.data?.sources || [];
  } catch {
    useAlert(t('KANBAN.PRODUCTS.LOAD_SOURCES_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const onFileSelected = event => {
  const file = event.target.files?.[0];
  if (file) {
    csvForm.file = file;
    if (!csvForm.name) {
      csvForm.name = file.name.replace(/\.[^/.]+$/, '');
    }
  }
};

const handleAddXmlSource = async () => {
  if (!xmlForm.name.trim() || !xmlForm.feed_url.trim()) return;

  isSubmitting.value = true;
  try {
    await KanbanProductSourcesAPI.createSource({
      name: xmlForm.name.trim(),
      source_type: 'google_merchant_xml',
      feed_url: xmlForm.feed_url.trim(),
    });
    useAlert(t('KANBAN.PRODUCTS.FEED_CREATED_SUCCESS'));
    xmlForm.name = '';
    xmlForm.feed_url = '';
    await fetchSources();
  } catch (error) {
    const errorMsg = error?.response?.data?.error || t('KANBAN.PRODUCTS.CREATE_ERROR');
    useAlert(errorMsg);
  } finally {
    isSubmitting.value = false;
  }
};

const handleUploadCsv = async () => {
  if (!csvForm.file) return;

  isSubmitting.value = true;
  try {
    const formData = new FormData();
    formData.append('file', csvForm.file);
    if (csvForm.name.trim()) {
      formData.append('name', csvForm.name.trim());
    }

    const response = await KanbanProductSourcesAPI.createSource(formData);
    const count = response.data?.items_count || 0;
    useAlert(t('KANBAN.PRODUCTS.CSV_IMPORTED_SUCCESS', { count }));
    csvForm.name = '';
    csvForm.file = null;
    if (fileInputRef.value) fileInputRef.value.value = '';
    await fetchSources();
  } catch (error) {
    const errorMsg = error?.response?.data?.error || t('KANBAN.PRODUCTS.CSV_IMPORT_ERROR');
    useAlert(errorMsg);
  } finally {
    isSubmitting.value = false;
  }
};

const downloadCsvTemplate = () => {
  const headers = ['id', 'title', 'price', 'description', 'image_link', 'link', 'brand', 'availability'];
  const sampleRows = [
    [
      'PROD-001',
      'Plano Mensal Consultoria Premium',
      '199.90 BRL',
      'Acesso completo aos serviços com suporte prioritário',
      'https://exemplo.com/imagens/prod-001.png',
      'https://exemplo.com/planos/premium',
      'Minha Empresa',
      'in_stock'
    ],
    [
      'PROD-002',
      'Treinamento de Equipe Comercial',
      '1450.00 BRL',
      'Workshop intensivo de 8 horas para qualificação de vendas',
      'https://exemplo.com/imagens/prod-002.png',
      'https://exemplo.com/treinamentos/comercial',
      'Minha Empresa',
      'in_stock'
    ]
  ];

  const csvContent = [
    headers.join(','),
    ...sampleRows.map(row => row.map(val => `"${String(val).replace(/"/g, '""')}"`).join(','))
  ].join('\n');

  const blob = new Blob(['\uFEFF' + csvContent], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.setAttribute('href', url);
  link.setAttribute('download', 'modelo_produtos_kanban.csv');
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(url);
};

const handleSync = async sourceId => {
  isSyncing.value[sourceId] = true;
  try {
    await KanbanProductSourcesAPI.syncSource(sourceId);
    useAlert(t('KANBAN.PRODUCTS.SYNC_STARTED'));
    setTimeout(fetchSources, 2000);
  } catch (error) {
    const errorMsg = error?.response?.data?.error || t('KANBAN.PRODUCTS.SYNC_ERROR');
    useAlert(errorMsg);
  } finally {
    isSyncing.value[sourceId] = false;
  }
};

const handleDelete = async sourceId => {
  if (!confirm(t('KANBAN.PRODUCTS.CONFIRM_DELETE_SOURCE'))) return;

  try {
    await KanbanProductSourcesAPI.deleteSource(sourceId);
    useAlert(t('KANBAN.PRODUCTS.SOURCE_DELETED'));
    await fetchSources();
  } catch {
    useAlert(t('KANBAN.PRODUCTS.DELETE_ERROR'));
  }
};

onMounted(() => {
  if (props.show) fetchSources();
});
</script>

<template>
  <woot-modal
    :show="show"
    :show-close-button="false"
    @close="emit('close')"
  >
    <div
      class="flex w-full max-w-2xl flex-col gap-5 rounded-lg bg-n-surface-1 p-6 text-n-slate-12"
      data-testid="kanban-products-modal"
    >
      <div class="flex items-center justify-between border-b border-n-weak pb-4">
        <div>
          <h3 class="text-lg font-semibold text-n-slate-12">
            {{ t('KANBAN.PRODUCTS.MODAL_TITLE') }}
          </h3>
          <p class="mb-0 text-sm text-n-slate-11">
            {{ t('KANBAN.PRODUCTS.MODAL_DESCRIPTION') }}
          </p>
        </div>
        <button
          type="button"
          class="rounded-md p-1.5 text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12"
          @click="emit('close')"
        >
          <i class="i-lucide-x size-5" />
        </button>
      </div>

      <!-- Formulário de Adição de Fonte -->
      <div class="rounded-lg border border-n-weak bg-n-surface-2 p-4">
        <div class="mb-3 flex gap-2 border-b border-n-weak pb-2 text-sm">
          <button
            type="button"
            class="px-3 py-1 font-medium rounded-md transition-colors"
            :class="activeTab === 'xml' ? 'bg-n-brand text-white' : 'text-n-slate-11 hover:text-n-slate-12'"
            @click="activeTab = 'xml'"
          >
            {{ t('KANBAN.PRODUCTS.TAB_GOOGLE_MERCHANT') }}
          </button>
          <button
            type="button"
            class="px-3 py-1 font-medium rounded-md transition-colors"
            :class="activeTab === 'csv' ? 'bg-n-brand text-white' : 'text-n-slate-11 hover:text-n-slate-12'"
            @click="activeTab = 'csv'"
          >
            {{ t('KANBAN.PRODUCTS.TAB_CSV_UPLOAD') }}
          </button>
        </div>

        <!-- Tab XML Google Merchant -->
        <form v-if="activeTab === 'xml'" class="grid gap-3" @submit.prevent="handleAddXmlSource">
          <div class="grid gap-1">
            <label class="text-xs font-medium text-n-slate-11">
              {{ t('KANBAN.PRODUCTS.FIELD_NAME') }}
            </label>
            <input
              v-model="xmlForm.name"
              type="text"
              class="reset-base h-8 rounded-md border border-n-weak bg-n-surface-1 px-3 text-sm text-n-slate-12 outline-none focus:border-n-brand"
              :placeholder="t('KANBAN.PRODUCTS.PLACEHOLDER_FEED_NAME')"
              required
            />
          </div>

          <div class="grid gap-1">
            <label class="text-xs font-medium text-n-slate-11">
              {{ t('KANBAN.PRODUCTS.FIELD_FEED_URL') }}
            </label>
            <input
              v-model="xmlForm.feed_url"
              type="url"
              class="reset-base h-8 rounded-md border border-n-weak bg-n-surface-1 px-3 text-sm text-n-slate-12 outline-none focus:border-n-brand"
              :placeholder="t('KANBAN.PRODUCTS.PLACEHOLDER_FEED_URL')"
              required
            />
          </div>

          <div class="flex justify-end pt-1">
            <Button
              type="submit"
              icon="i-lucide-plus"
              :label="t('KANBAN.PRODUCTS.ADD_FEED_BUTTON')"
              :is-loading="isSubmitting"
              :disabled="isSubmitting || !xmlForm.name || !xmlForm.feed_url"
            />
          </div>
        </form>

        <!-- Tab CSV Upload -->
        <form v-else class="grid gap-3" @submit.prevent="handleUploadCsv">
          <div class="flex items-center justify-between rounded-md bg-n-surface-1 p-2.5 border border-n-weak">
            <div class="text-xs text-n-slate-11">
              <span class="font-medium text-n-slate-12 block mb-0.5">
                {{ t('KANBAN.PRODUCTS.DOWNLOAD_TEMPLATE_CSV') }}
              </span>
              <span>{{ t('KANBAN.PRODUCTS.CSV_HINT') }}</span>
            </div>
            <Button
              type="button"
              icon="i-lucide-download"
              slate
              outline
              xs
              :label="t('KANBAN.PRODUCTS.DOWNLOAD_TEMPLATE_CSV')"
              @click="downloadCsvTemplate"
            />
          </div>

          <div class="grid gap-1">
            <label class="text-xs font-medium text-n-slate-11">
              {{ t('KANBAN.PRODUCTS.FIELD_CSV_NAME') }}
            </label>
            <input
              v-model="csvForm.name"
              type="text"
              class="reset-base h-8 rounded-md border border-n-weak bg-n-surface-1 px-3 text-sm text-n-slate-12 outline-none focus:border-n-brand"
              :placeholder="t('KANBAN.PRODUCTS.PLACEHOLDER_CSV_NAME')"
            />
          </div>

          <div class="grid gap-1">
            <label class="text-xs font-medium text-n-slate-11">
              {{ t('KANBAN.PRODUCTS.FIELD_FILE') }}
            </label>
            <input
              ref="fileInputRef"
              type="file"
              accept=".csv"
              class="text-sm text-n-slate-11 file:mr-3 file:rounded-md file:border-0 file:bg-n-brand file:px-3 file:py-1 file:text-xs file:font-semibold file:text-white hover:file:opacity-90"
              required
              @change="onFileSelected"
            />
          </div>

          <div class="flex justify-end pt-1">
            <Button
              type="submit"
              icon="i-lucide-upload"
              :label="t('KANBAN.PRODUCTS.IMPORT_CSV_BUTTON')"
              :is-loading="isSubmitting"
              :disabled="isSubmitting || !csvForm.file"
            />
          </div>
        </form>
      </div>

      <!-- Lista de Fontes Existentes -->
      <div class="grid gap-2">
        <h4 class="text-sm font-semibold text-n-slate-12">
          {{ t('KANBAN.PRODUCTS.EXISTING_SOURCES_TITLE') }}
        </h4>

        <div v-if="isLoading" class="text-center py-4 text-sm text-n-slate-11">
          {{ t('KANBAN.PRODUCTS.LOADING') }}
        </div>

        <div v-else-if="!sources.length" class="text-center py-4 text-sm text-n-slate-11 border border-dashed border-n-weak rounded-md">
          {{ t('KANBAN.PRODUCTS.NO_SOURCES_YET') }}
        </div>

        <div v-else class="max-h-60 overflow-y-auto space-y-2">
          <div
            v-for="src in sources"
            :key="src.id"
            class="flex items-center justify-between gap-3 rounded-lg border border-n-weak bg-n-surface-1 p-3 text-sm"
          >
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-2">
                <span class="font-medium truncate text-n-slate-12">{{ src.name }}</span>
                <span
                  class="rounded px-1.5 py-0.5 text-[10px] font-semibold uppercase"
                  :class="src.source_type === 'google_merchant_xml' ? 'bg-n-brand/10 text-n-brand' : 'bg-n-teal-9/10 text-n-teal-11'"
                >
                  {{ src.source_type === 'google_merchant_xml' ? 'Google XML' : 'CSV' }}
                </span>
              </div>

              <p v-if="src.feed_url" class="mb-0 text-xs text-n-slate-10 truncate" :title="src.feed_url">
                {{ src.feed_url }}
              </p>

              <div class="mt-1 flex items-center gap-3 text-xs text-n-slate-11">
                <span>{{ t('KANBAN.PRODUCTS.ITEMS_COUNT', { count: src.items_count }) }}</span>
                <span
                  class="flex items-center gap-1"
                  :class="src.last_sync_status === 'success' ? 'text-n-teal-11' : (src.last_sync_status === 'failed' ? 'text-n-ruby-11' : 'text-n-amber-11')"
                >
                  <i
                    :class="src.last_sync_status === 'success' ? 'i-lucide-check-circle' : (src.last_sync_status === 'failed' ? 'i-lucide-alert-circle' : 'i-lucide-clock')"
                    class="size-3.5"
                  />
                  {{ src.last_sync_status }}
                </span>
              </div>

              <p v-if="src.last_sync_error" class="mb-0 mt-1 text-[11px] text-n-ruby-11 truncate" :title="src.last_sync_error">
                {{ src.last_sync_error }}
              </p>
            </div>

            <div class="flex items-center gap-2 flex-shrink-0">
              <Button
                v-if="src.source_type === 'google_merchant_xml'"
                icon="i-lucide-refresh-cw"
                slate
                xs
                outline
                :is-loading="isSyncing[src.id]"
                :title="t('KANBAN.PRODUCTS.SYNC_NOW')"
                @click="handleSync(src.id)"
              />
              <Button
                icon="i-lucide-trash-2"
                ruby
                xs
                outline
                :title="t('KANBAN.PRODUCTS.DELETE_SOURCE')"
                @click="handleDelete(src.id)"
              />
            </div>
          </div>
        </div>
      </div>

      <div class="flex justify-end pt-2 border-t border-n-weak">
        <Button
          slate
          outline
          :label="t('KANBAN.PRODUCTS.CLOSE')"
          @click="emit('close')"
        />
      </div>
    </div>
  </woot-modal>
</template>
