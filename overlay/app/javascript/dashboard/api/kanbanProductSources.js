import ApiClient from './ApiClient';

class KanbanProductSourcesAPI extends ApiClient {
  constructor() {
    super('kanban_product_sources', { accountScoped: true });
  }

  getSources() {
    return this.get();
  }

  createSource(data) {
    if (data instanceof FormData) {
      return axios.post(`${this.url}`, data, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
    }
    return this.post('', { kanban_product_source: data });
  }

  syncSource(sourceId) {
    return this.post(`${sourceId}/sync`);
  }

  deleteSource(sourceId) {
    return this.delete(`${sourceId}`);
  }
}

export default new KanbanProductSourcesAPI();
